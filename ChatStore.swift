import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let client = GeminiClient()
    private let storageKey = "chatMessages"

    init() {
        loadMessages()
    }

    func send(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isSending else { return }

        let userMessage = ChatMessage(role: .user, text: trimmedText)
        messages.append(userMessage)
        isSending = true
        errorMessage = nil
        persistMessages()

        do {
            let answer = try await client.send(messages: messages)
            messages.append(ChatMessage(role: .assistant, text: answer))
            persistMessages()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    func clearConversation() {
        messages = []
        errorMessage = nil
        persistMessages()
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return
        }
        messages = savedMessages
    }

    private func persistMessages() {
        guard let data = try? JSONEncoder().encode(messages.suffix(50)) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
