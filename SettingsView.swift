import SwiftUI

struct SettingsView: View {
    @AppStorage("geminiAPIKey") private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Gemini API") {
                    SecureField("API-ключ", text: $apiKey)
                    Link("Получить ключ", destination: URL(string: "https://aistudio.google.com/apikey")!)
                }

                Section {
                    Text("Ключ хранится локально на часах. Для публичного приложения лучше использовать собственный сервер-прокси, чтобы не раскрывать ключ в клиенте.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
