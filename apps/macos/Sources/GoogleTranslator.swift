import Foundation

/// Uses Google Translate's free `gtx` endpoint. No API key required.
/// Response shape: [ [[ "translated", "source", ... ], ...], ..., "detectedLang", ... ]
final class GoogleTranslator: Translator {
    let engine: TranslationEngine = .google

    private let endpoint = "https://translate.googleapis.com/translate_a/single"

    func translate(
        text: String,
        sourceLanguage: String?,
        targetLanguage: String
    ) async throws -> TranslationResult {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLanguage ?? "auto"),
            URLQueryItem(name: "tl", value: targetLanguage),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]
        guard let url = components.url else { throw TranslationError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 Glance/0.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw TranslationError.httpError(http.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            throw TranslationError.invalidResponse
        }

        var translated = ""
        if let segments = json.first as? [[Any]] {
            for segment in segments {
                if let part = segment.first as? String {
                    translated += part
                }
            }
        }

        let detected = (json.count > 2 ? (json[2] as? String) : nil) ?? "auto"

        let trimmed = translated.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranslationError.emptyResult }

        return TranslationResult(
            translatedText: translated,
            sourceLanguage: detected,
            targetLanguage: targetLanguage,
            engine: .google
        )
    }
}
