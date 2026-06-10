//
//  ChatRoomViewModel.swift
//  alp
//
//  Created by Vincent on 10/06/26.
//
import Foundation
import XCTest
import FirebaseFirestore
@testable import alp

private final class MockListenerRegistration: NSObject, ListenerRegistration {
    private(set) var removeCallCount = 0

    func remove() {
        removeCallCount += 1
    }
}

private final class MockChatService: ChatServiceProtocol {
    var messages: [ChatMessage] = []
    var shouldThrowOnSend = false
    var shouldThrowOnMarkRead = false
    var observeError: Error?
    var sentMessages: [ChatMessage] = []
    var markedReadCalls: [(roomId: String, userId: String)] = []
    var listener = MockListenerRegistration()
    private var completion: ((Result<[ChatMessage], Error>) -> Void)?

    func sendMessage(_ message: ChatMessage) async throws {
        if shouldThrowOnSend { throw testError }
        sentMessages.append(message)
        messages.append(message)
        completion?(.success(messages.filter { $0.roomId == message.roomId }))
    }

    func markRoomRead(roomId: String, userId: String) async throws {
        if shouldThrowOnMarkRead { throw testError }
        markedReadCalls.append((roomId: roomId, userId: userId))
    }

    func observeMessages(roomId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration? {
        self.completion = completion
        if let observeError {
            completion(.failure(observeError))
        } else {
            completion(.success(messages.filter { $0.roomId == roomId }))
        }
        return listener
    }

    func emit(_ messages: [ChatMessage]) {
        self.messages = messages
        completion?(.success(messages))
    }

    private var testError: NSError {
        NSError(domain: "ChatServiceTests", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

private final class MockRoomService: RoomServiceProtocol {
    var rooms: [Room] = []
    var shouldThrowOnCreate = false
    var observeError: Error?
    var createdRoomRequests: [(name: String, eventId: String, participants: [User], owner: User)] = []
    var nextRoomId = "room-new"
    var listener = MockListenerRegistration()
    private(set) var observeCallCount = 0
    private var completion: ((Result<[Room], Error>) -> Void)?

    func observeRooms(for userId: String, eventId: String, completion: @escaping (Result<[Room], Error>) -> Void) -> ListenerRegistration {
        observeCallCount += 1
        self.completion = completion
        if let observeError {
            completion(.failure(observeError))
        } else {
            completion(.success(rooms))
        }
        return listener
    }

    func createRoom(name: String, eventId: String, participants: [User], owner: User) async throws -> String {
        if shouldThrowOnCreate { throw testError }
        createdRoomRequests.append((name: name, eventId: eventId, participants: participants, owner: owner))
        return nextRoomId
    }

    func emit(_ rooms: [Room]) {
        self.rooms = rooms
        completion?(.success(rooms))
    }

    private var testError: NSError {
        NSError(domain: "RoomServiceTests", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

@MainActor
final class ChatViewModelTests: XCTestCase {
    private var viewModel: ChatViewModel!
    private var service: MockChatService!

    override func setUp() {
        super.setUp()
        service = MockChatService()
        viewModel = ChatViewModel(service: service)
    }

    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }

    func testStartListeningSortsMessagesAndMarksRoomRead() async throws {
        service.messages = [
            makeMessage(id: "late", text: "Kedua", timestamp: Date(timeIntervalSince1970: 200)),
            makeMessage(id: "early", text: "Pertama", timestamp: Date(timeIntervalSince1970: 100)),
            makeMessage(id: "other-room", roomId: "room-b", text: "Room lain", timestamp: Date(timeIntervalSince1970: 50))
        ]

        viewModel.startListening(roomId: "room-a", userId: "user-1")
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.messages.compactMap(\.id), ["early", "late"])
        XCTAssertEqual(service.markedReadCalls.map { $0.roomId }, ["room-a"])
        XCTAssertEqual(service.markedReadCalls.map { $0.userId }, ["user-1"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStartListeningFailureSetsErrorMessage() async throws {
        service.observeError = NSError(domain: "ChatServiceTests", code: 400, userInfo: [NSLocalizedDescriptionKey: "Observe failed"])

        viewModel.startListening(roomId: "room-a", userId: "user-1")
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.errorMessage, "Gagal memuat pesan: Observe failed")
    }

    func testSendMessageTrimsTextAppendsOptimisticallyAndPersists() async throws {
        viewModel.startListening(roomId: "room-a", userId: "user-1")

        let success = await viewModel.sendMessage(roomId: "room-a", senderId: "user-1", senderName: "Budi", text: "  Halo tim  ")
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.text, "Halo tim")
        XCTAssertEqual(service.sentMessages.first?.text, "Halo tim")
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSendMessageRejectsEmptyText() async {
        let success = await viewModel.sendMessage(roomId: "room-a", senderId: "user-1", senderName: "Budi", text: "   ")

        XCTAssertFalse(success)
        XCTAssertTrue(service.sentMessages.isEmpty)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Pesan tidak boleh kosong.")
    }

    func testSendMessageRejectsInvalidRoomOrUser() async {
        let success = await viewModel.sendMessage(roomId: "", senderId: "user-1", senderName: "Budi", text: "Halo")

        XCTAssertFalse(success)
        XCTAssertTrue(service.sentMessages.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Room atau user tidak valid.")
    }

    func testSendMessageFailureRollsBackOptimisticMessage() async throws {
        viewModel.startListening(roomId: "room-a", userId: "user-1")
        try await Task.sleep(nanoseconds: 50_000_000)
        service.shouldThrowOnSend = true

        let success = await viewModel.sendMessage(roomId: "room-a", senderId: "user-1", senderName: "Budi", text: "Halo")

        XCTAssertFalse(success)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Gagal mengirim pesan: Mock failure")
        XCTAssertFalse(viewModel.isSending)
    }

    func testStopListeningRemovesActiveListener() {
        viewModel.startListening(roomId: "room-a")

        viewModel.stopListening()

        XCTAssertEqual(service.listener.removeCallCount, 1)
    }

    private func makeMessage(
        id: String,
        roomId: String = "room-a",
        text: String,
        timestamp: Date
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            roomId: roomId,
            senderId: "user-1",
            senderName: "Budi",
            text: text,
            timestamp: timestamp
        )
    }
}

@MainActor
final class RoomViewModelTests: XCTestCase {
    private var viewModel: RoomViewModel!
    private var service: MockRoomService!

    override func setUp() {
        super.setUp()
        service = MockRoomService()
        viewModel = RoomViewModel(service: service)
    }

    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }

    func testStartListeningWithEmptyUserOrEventClearsRoomsWithoutStartingListener() {
        viewModel.rooms = [makeRoom(id: "room-existing", name: "Existing")]

        viewModel.startListening(for: "", eventId: "event-a")

        XCTAssertTrue(viewModel.rooms.isEmpty)
        XCTAssertEqual(service.observeCallCount, 0)
    }

    func testStartListeningUpdatesRoomsAndClearsError() async throws {
        service.rooms = [
            makeRoom(id: "room-1", name: "Panitia Inti"),
            makeRoom(id: "room-2", name: "Logistik")
        ]
        viewModel.errorMessage = "Old error"

        viewModel.startListening(for: "user-1", eventId: "event-a")
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.rooms.map(\.name), ["Panitia Inti", "Logistik"])
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    func testStartListeningFailureSetsErrorMessage() async throws {
        service.observeError = NSError(domain: "RoomServiceTests", code: 400, userInfo: [NSLocalizedDescriptionKey: "Observe failed"])

        viewModel.startListening(for: "user-1", eventId: "event-a")
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.errorMessage, "Gagal memuat room: Observe failed")
    }

    func testCreateRoomTrimsNameAndReturnsCreatedId() async {
        let owner = makeUser(id: "owner-1", name: "Owner")
        let member = makeUser(id: "member-1", name: "Member")

        let roomId = await viewModel.createRoom(name: "  Koordinasi Acara  ", eventId: "event-a", selectedUsers: [member], owner: owner)

        XCTAssertEqual(roomId, "room-new")
        XCTAssertEqual(service.createdRoomRequests.first?.name, "Koordinasi Acara")
        XCTAssertEqual(service.createdRoomRequests.first?.eventId, "event-a")
        XCTAssertEqual(service.createdRoomRequests.first?.participants.compactMap(\.id), ["member-1"])
        XCTAssertEqual(service.createdRoomRequests.first?.owner.id, "owner-1")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.isCreatingRoom)
    }

    func testCreateRoomRejectsEmptyName() async {
        let roomId = await viewModel.createRoom(name: "   ", eventId: "event-a", selectedUsers: [makeUser(id: "member-1")], owner: makeUser(id: "owner-1"))

        XCTAssertNil(roomId)
        XCTAssertTrue(service.createdRoomRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Nama room wajib diisi.")
    }

    func testCreateRoomRejectsInvalidOwner() async {
        let invalidOwner = User(id: nil, name: "Owner", email: "owner@test.com")

        let roomId = await viewModel.createRoom(name: "Room", eventId: "event-a", selectedUsers: [makeUser(id: "member-1")], owner: invalidOwner)

        XCTAssertNil(roomId)
        XCTAssertTrue(service.createdRoomRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "User aktif tidak valid.")
    }

    func testCreateRoomRejectsEmptyEvent() async {
        let roomId = await viewModel.createRoom(name: "Room", eventId: "", selectedUsers: [makeUser(id: "member-1")], owner: makeUser(id: "owner-1"))

        XCTAssertNil(roomId)
        XCTAssertTrue(service.createdRoomRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Event aktif tidak valid.")
    }

    func testCreateRoomRejectsEmptySelectedUsers() async {
        let roomId = await viewModel.createRoom(name: "Room", eventId: "event-a", selectedUsers: [], owner: makeUser(id: "owner-1"))

        XCTAssertNil(roomId)
        XCTAssertTrue(service.createdRoomRequests.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Pilih minimal satu anggota event.")
    }

    func testCreateRoomFailureSetsErrorAndStopsLoading() async {
        service.shouldThrowOnCreate = true

        let roomId = await viewModel.createRoom(name: "Room", eventId: "event-a", selectedUsers: [makeUser(id: "member-1")], owner: makeUser(id: "owner-1"))

        XCTAssertNil(roomId)
        XCTAssertEqual(viewModel.errorMessage, "Gagal membuat room: Mock failure")
        XCTAssertFalse(viewModel.isCreatingRoom)
    }

    func testStopListeningRemovesActiveListener() {
        viewModel.startListening(for: "user-1", eventId: "event-a")

        viewModel.stopListening()

        XCTAssertEqual(service.listener.removeCallCount, 1)
    }

    private func makeRoom(id: String, name: String) -> Room {
        Room(
            id: id,
            name: name,
            eventId: "event-a",
            participants: ["user-1"],
            participantNames: ["Budi"],
            participantEmails: ["budi@test.com"],
            createdAt: Date(timeIntervalSince1970: 1_000),
            ownerId: "owner-1",
            ownerEmail: "owner@test.com",
            lastMessage: nil,
            lastTimestamp: nil,
            readBy: nil
        )
    }

    private func makeUser(id: String, name: String = "User") -> User {
        User(id: id, name: name, email: "\(id)@test.com")
    }
}

