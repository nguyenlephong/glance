import Foundation

enum TranslationEngine: String, Codable, CaseIterable, Identifiable {
    case google
    case openai
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: return "Google"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }
}

struct TranslationResult: Equatable {
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let engine: TranslationEngine
}

protocol Translator {
    var engine: TranslationEngine { get }
    /// Dịch văn bản. `sourceLanguage` = nil ⇒ tự detect.
    func translate(
        text: String,
        sourceLanguage: String?,
        targetLanguage: String
    ) async throws -> TranslationResult
}

enum TranslationError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Phản hồi không hợp lệ từ dịch vụ dịch."
        case .httpError(let code): return "Lỗi HTTP \(code) từ dịch vụ dịch."
        case .emptyResult: return "Không có kết quả dịch."
        }
    }
}
