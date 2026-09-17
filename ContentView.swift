import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var chatStore: ChatStore
    @State private var draft = ""
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                if chatStore.messages.isEmpty {
                    emptyState
                } else {
                    messagesList
                }

                if let errorMessage = chatStore.errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                composer
            }
            .padding(.horizontal, 8)
            .navigationTitle("Gemini")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Настройки")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        chatStore.clearConversation()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(chatStore.messages.isEmpty || chatStore.isSending)
                    .accessibilityLabel("Очистить чат")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text("Спроси Gemini")
                .font(.headline)
            Text("Короткие ответы прямо на запястье")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 7) {
                    ForEach(chatStore.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if chatStore.isSending {
                        ProgressView("Думаю...")
                            .font(.caption2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .onChange(of: chatStore.messages.count) { _, _ in
                if let lastMessage = chatStore.messages.last {
                    withAnimation { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 6) {
            TextField("Напиши вопрос", text: $draft, axis: .vertical)
                .lineLimit(1...3)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatStore.isSending)
            .accessibilityLabel("Отправить")
        }
        .padding(.bottom, 2)
    }

    private func sendMessage() {
        let text = draft
        draft = ""
        Task { await chatStore.send(text) }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { bubble } else { Spacer(minLength: 18); bubble }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(.caption)
            .foregroundStyle(message.role == .assistant ? Color.primary : Color.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(message.role == .assistant ? Color.gray.opacity(0.22) : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
