import XCTest
import FirebaseFirestore
@testable import NamaAplikasiAnda // Sesuaikan dengan target Anda

// Mock Service
class MockChatService: ChatServiceProtocol {
    var mockMessages: [ChatMessage] = []
    var shouldThrowError = false
    
    // Menyimpan closure dari listener untuk kita panggil secara manual saat testing
    var capturedCompletion: ((Result<[ChatMessage], Error>) -> Void)?
    
    func sendMessage(_ message: ChatMessage) async throws {
        if shouldThrowError { throw NSError(domain: "Test", code: 500) }
        var msg = message
        msg.id = UUID().uuidString
        mockMessages.append(msg)
        
        // Simulasikan behavior Firebase: saat data bertambah, listener otomatis terpanggil
        capturedCompletion?(.success(mockMessages))
    }
    
    func observeMessages(roomId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration? {
        capturedCompletion = completion
        
        if shouldThrowError {
            completion(.failure(NSError(domain: "Test", code: 500)))
        } else {
            let filtered = mockMessages.filter { $0.roomId == roomId }
            completion(.success(filtered))
        }
        return nil // Mock tidak butuh object ListenerRegistration asli
    }
}

@MainActor
final class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockService: MockChatService!
    
    override func setUp() {
        super.setUp()
        mockService = MockChatService()
        viewModel = ChatViewModel(service: mockService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testObserveMessagesSuccess() {
        let msg = ChatMessage(id: "msg1", roomId: "room_A", senderId: "usr1", senderName: "Budi", text: "Halo tim!", timestamp: Date())
        mockService.mockMessages = [msg]
        
        viewModel.startListening(roomId: "room_A")
        
        // Kita gunakan sedikit delay karena DispatchQueue.main.async di dalam ViewModel
        let expectation = XCTestExpectation(description: "Tunggu listener update array")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.messages.count, 1)
            XCTAssertEqual(self.viewModel.messages.first?.text, "Halo tim!")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSendMessageTriggersListener() async {
        // Mulai mendengarkan ruangan tertentu
        viewModel.startListening(roomId: "room_A")
        
        // Kirim pesan baru
        await viewModel.sendMessage(roomId: "room_A", senderId: "usr2", senderName: "Andi", text: "Saya sudah di lokasi")
        
        // Array pesan harus otomatis ter-update oleh listener
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.text, "Saya sudah di lokasi")
    }
}