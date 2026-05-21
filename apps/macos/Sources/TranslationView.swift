import SwiftUI

enum TranslationState: Equatable {
    case loading
    case success(TranslationResult)
    case failure(String)
}

final class TranslationViewModel: ObservableObject {
    @Published var state: TranslationState = .loading
    @Published var originalText: String = ""
}

struct TranslationView: View {
    @ObservedObject var viewModel: TranslationViewModel
    var onDismiss: () -> Void
    var onSwap: () -> Void
    var onReplace: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider().opacity(0.4)
            content
            if case .success = viewModel.state {
                Divider().opacity(0.4)
                actionsBar
            }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            languagePill(text: sourceLabel)

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Đảo chiều dịch")
            .disabled(!canAct)
            .opacity(canAct ? 1 : 0.4)

            languagePill(text: targetLabel)
            Spacer()
            engineBadge
        }
    }

    // MARK: - Content

    private var content: some View {
        Group {
            switch viewModel.state {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Đang dịch…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            case .success(let result):
                Text(result.translatedText)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            case .failure(let message):
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions bar

    private var actionsBar: some View {
        HStack(spacing: 8) {
            // Primary — Replace (filled, accent)
            Button(action: onReplace) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.left.circle.fill")
                    Text("Replace")
                        .fontWeight(.semibold)
                    Text("⌃⌥⏎")
                        .font(.caption2.monospaced())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.white.opacity(0.22)))
                }
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .help("Thay đoạn văn bản đang bôi đen bằng bản dịch")

            // Secondary — Copy
            Button(action: copyTranslation) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .help("Sao chép bản dịch vào clipboard")

            // Tertiary — Dismiss
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Đóng (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    // MARK: - Helpers

    private func copyTranslation() {
        guard case .success(let result) = viewModel.state else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(result.translatedText, forType: .string)
    }

    private var canAct: Bool {
        if case .success = viewModel.state { return true }
        return false
    }

    private var sourceLabel: String {
        if case .success(let result) = viewModel.state {
            return result.sourceLanguage.uppercased()
        }
        return "AUTO"
    }

    private var targetLabel: String {
        if case .success(let result) = viewModel.state {
            return result.targetLanguage.uppercased()
        }
        return AppSettings.shared.primaryLanguage.uppercased()
    }

    private var engineBadge: some View {
        let name: String = {
            if case .success(let result) = viewModel.state {
                return result.engine.displayName
            }
            return AppSettings.shared.engine.displayName
        }()
        return Text(name)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.accentColor.opacity(0.18)))
            .foregroundStyle(Color.accentColor)
    }

    private func languagePill(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
            .foregroundStyle(.primary)
    }
}
