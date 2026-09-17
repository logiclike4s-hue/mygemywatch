import Foundation

struct GeminiClient {
    private let model = "gemini-2.5-flash"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    func send(messages: [ChatMessage]) async throws -> String {
        let localKey = UserDefaults.standard.string(forKey: "geminiAPIKey")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let buildKey = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = localKey?.isEmpty == false ? localKey : buildKey

        guard let apiKey,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        let contents = messages.suffix(20).map { message in
            GeminiContent(
                role: message.role == .user ? "user" : "model",
                parts: [GeminiPart(text: message.text)]
            )
        }
        let requestBody = GeminiRequest(contents: Array(contents))

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw GeminiError.server(statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.first?.text,
              !text.isEmpty else {
            throw GeminiError.emptyResponse
        }
        return text
    }
}

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig = GenerationConfig()
}

private struct GenerationConfig: Encodable {
    let temperature = 0.7
    let maxOutputTokens = 300
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case server(statusCode: Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Добавьте ключ Gemini в настройках."
        case .invalidURL, .invalidResponse:
            return "Не удалось связаться с Gemini."
        case .server(let statusCode):
            return "Gemini вернул ошибку \(statusCode)."
        case .emptyResponse:
            return "Gemini не вернул текст ответа."
        }
    }
}
