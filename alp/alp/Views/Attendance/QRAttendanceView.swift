//
//  QRAttendanceView.swift
//  alp
//
//  Created by Lemuel on 04/06/26.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

private enum DSQR {
    static let indigo      = Color(red: 0.29, green: 0.34, blue: 0.90)
    static let purple      = Color(red: 0.58, green: 0.28, blue: 0.90)
    static let indigoMuted = Color(red: 0.29, green: 0.34, blue: 0.90).opacity(0.12)
    static let bgPrimary   = Color(UIColor.systemGroupedBackground)
    static let bgSurface   = Color(UIColor.secondarySystemGroupedBackground)
    static let textPrimary   = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary  = Color(UIColor.tertiaryLabel)
    static let border = Color(UIColor.separator).opacity(0.4)
    static let brandGradient = LinearGradient(
        colors: [indigo, purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

private enum QRTab: String, CaseIterable {
    case generate = "QR Code"
    case scan     = "Scan QR"
}

struct QRAttendanceView: View {
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    @EnvironmentObject var memberVM: EventMemberViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass

    var record: AttendanceRecord?

    var onScanComplete: ((String) -> Void)? = nil

    @State private var selectedTab: QRTab = .generate
    @State private var scannedUserId: String? = nil
    @State private var showScanResult = false
    @State private var scanResultIsSuccess = false
    @State private var scanResultMessage = ""

    private var qrPayload: String {
        record?.id ?? "no-record"
    }

    var body: some View {
        ZStack {
            DSQR.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Segmented Tab
                Picker("Mode", selection: $selectedTab) {
                    ForEach(QRTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: Tab Content
                switch selectedTab {
                case .generate:
                    QRGeneratePanel(payload: qrPayload, record: record)
                        .transition(.opacity)
                case .scan:
                    QRScanPanel(
                        onScanned: handleScannedCode(_:)
                    )
                    .transition(.opacity)
                }
            }
        }
        .navigationTitle("QR Presence")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .preferredColorScheme(.light)
        .alert(scanResultIsSuccess ? "Berhasil ✓" : "Gagal", isPresented: $showScanResult) {
            Button("OK") { }
        } message: {
            Text(scanResultMessage)
        }
    }

    private func handleScannedCode(_ code: String) {
        guard code.hasPrefix("alp-attendance://") else {
            scanResultMessage = "QR code tidak dikenali. Pastikan menggunakan QR dari aplikasi ALP."
            scanResultIsSuccess = false
            showScanResult = true
            return
        }

        let userId = String(code.dropFirst("alp-attendance://".count))

        guard let rec = record, let recordId = rec.id else {
            scanResultMessage = "Sesi presensi belum tersimpan. Buat dan simpan sesi terlebih dahulu."
            scanResultIsSuccess = false
            showScanResult = true
            return
        }

        guard memberVM.getUser(byId: userId) != nil else {
            scanResultMessage = "Anggota tidak ditemukan dalam event ini."
            scanResultIsSuccess = false
            showScanResult = true
            return
        }

        if rec.attendedMemberIds.contains(userId) {
            scanResultMessage = "Anggota ini sudah tercatat hadir."
            scanResultIsSuccess = false
            showScanResult = true
            return
        }

        var updatedIds   = rec.attendedMemberIds
        var updatedTimes = rec.attendanceTimes
        updatedIds.append(userId)
        updatedTimes[userId] = Date()

        attendanceVM.updateAttendance(
            recordId: recordId,
            attendedMemberIds: updatedIds,
            attendanceTimes: updatedTimes
        )

        let userName = memberVM.getUser(byId: userId)?.name ?? userId
        scanResultMessage = "\(userName) berhasil dicatat hadir."
        scanResultIsSuccess = true
        showScanResult = true
        onScanComplete?(userId)
    }
}

private struct QRGeneratePanel: View {
    let payload: String
    let record: AttendanceRecord?

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                if let rec = record {
                    infoCard(rec)
                }

                VStack(spacing: 20) {
                    sectionHeader("QR Code Sesi")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        Image(uiImage: generateQRCode(from: payload))
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: DSQR.indigo.opacity(0.12), radius: 16, x: 0, y: 6)

                        Text("Tunjukkan QR ini kepada peserta\nuntuk melakukan scan kehadiran")
                            .font(.system(size: 13))
                            .foregroundColor(DSQR.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .background(DSQR.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(DSQR.border, lineWidth: 1)
                )

                memberHintCard

            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: 500)
            .scaleEffect(sizeClass == .regular ? 1.3 : 1.0, anchor: .top)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, sizeClass == .regular ? 300 : 0)
        }
    }

    private func infoCard(_ rec: AttendanceRecord) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DSQR.indigoMuted)
                    .frame(width: 44, height: 44)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DSQR.indigo)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(rec.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DSQR.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text(rec.date, style: .time)
                    Text("•")
                    Text(rec.date, style: .date)
                }
                .font(.system(size: 12))
                .foregroundColor(DSQR.textSecondary)
                Text("Hadir: \(rec.attendedMemberIds.count) / \(rec.targetMemberIds.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DSQR.indigo)
            }
            Spacer()
        }
        .padding(14)
        .background(DSQR.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DSQR.border, lineWidth: 1)
        )
    }

    private var memberHintCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(DSQR.indigo)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text("Cara menggunakan")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DSQR.textPrimary)
                Text("Tampilkan QR ini di layar. Setiap anggota membuka fitur **Scan QR** di aplikasi mereka dan mengarahkan kamera ke QR ini. Kehadiran langsung tercatat secara otomatis.")
                    .font(.system(size: 13))
                    .foregroundColor(DSQR.textSecondary)
            }
        }
        .padding(14)
        .background(DSQR.indigo.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DSQR.brandGradient)
                .frame(width: 3, height: 16)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DSQR.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }

    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter  = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        if let output = filter.outputImage,
           let cgImg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImg)
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

private struct QRScanPanel: View {
    let onScanned: (String) -> Void

    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var lastScanned: String = ""

    var body: some View {
        switch cameraPermission {
        case .authorized:
            scannerBody
        case .notDetermined:
            permissionRequestView
        default:
            permissionDeniedView
        }
    }

    private var scannerBody: some View {
        ZStack {
            QRCameraPreview(onCodeScanned: { code in
                guard code != lastScanned else { return }
                lastScanned = code
                onScanned(code)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    lastScanned = ""
                }
            })
            .ignoresSafeArea()

            VStack {
                Spacer()
                ZStack {
                    Color.black.opacity(0.55)
                        .mask(
                            Rectangle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(width: 240, height: 240)
                                        .blendMode(.destinationOut)
                                )
                        )
                    QRCornerAccents()
                        .frame(width: 240, height: 240)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                Spacer()

                Text("Arahkan kamera ke QR Code sesi presensi")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DSQR.indigoMuted)
                    .frame(width: 80, height: 80)
                Image(systemName: "camera.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(DSQR.indigo)
            }
            VStack(spacing: 6) {
                Text("Akses Kamera Diperlukan")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DSQR.textPrimary)
                Text("Izinkan akses kamera untuk dapat scan QR presensi.")
                    .font(.system(size: 14))
                    .foregroundColor(DSQR.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        cameraPermission = granted ? .authorized : .denied
                    }
                }
            }) {
                Text("Izinkan Kamera")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DSQR.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 40)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "camera.fill.badge.ellipsis")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.red)
            }
            VStack(spacing: 6) {
                Text("Kamera Diblokir")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DSQR.textPrimary)
                Text("Buka Settings dan aktifkan izin kamera untuk aplikasi ini.")
                    .font(.system(size: 14))
                    .foregroundColor(DSQR.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Buka Settings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 40)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


private struct QRCornerAccents: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 28
            let thick: CGFloat = 4
            let r: CGFloat = 10
            let color = Color.white

            ZStack {
                // Top-left
                cornerShape(len: len, thick: thick, r: r, color: color)
                    .rotationEffect(.degrees(0))
                    .position(x: 0, y: 0)

                // Top-right
                cornerShape(len: len, thick: thick, r: r, color: color)
                    .rotationEffect(.degrees(90))
                    .position(x: w, y: 0)

                // Bottom-right
                cornerShape(len: len, thick: thick, r: r, color: color)
                    .rotationEffect(.degrees(180))
                    .position(x: w, y: h)

                // Bottom-left
                cornerShape(len: len, thick: thick, r: r, color: color)
                    .rotationEffect(.degrees(270))
                    .position(x: 0, y: h)
            }
        }
    }

    private func cornerShape(len: CGFloat, thick: CGFloat, r: CGFloat, color: Color) -> some View {
        ZStack(alignment: .topLeading) {
            // Horizontal arm
            RoundedRectangle(cornerRadius: thick / 2)
                .fill(color)
                .frame(width: len, height: thick)
            // Vertical arm
            RoundedRectangle(cornerRadius: thick / 2)
                .fill(color)
                .frame(width: thick, height: len)
        }
        .frame(width: len, height: len)
    }
}

struct QRCameraPreview: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> QRPreviewUIView {
        let view = QRPreviewUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: QRPreviewUIView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                object.type == .qr,
                let stringValue = object.stringValue
            else { return }

            DispatchQueue.main.async {
                self.onCodeScanned(stringValue)
            }
        }
    }
}

final class QRPreviewUIView: UIView {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSession()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSession()
    }

    private func setupSession() {
        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(delegate, queue: .main)
        metadataOutput.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        previewLayer = preview
        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            captureSession?.stopRunning()
        } else if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }
}
