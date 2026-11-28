import SwiftUI
import UniformTypeIdentifiers

/// Выбор файла с asCopy: система сама копирует файл в песочницу приложения (в том числе
/// из iCloud и сторонних провайдеров) и отдаёт готовую локальную копию.
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        vc.allowsMultipleSelection = false
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(_ p: DocumentPicker) { parent = p }
        func documentPicker(_ c: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let u = urls.first { parent.onPick(u) } else { parent.onCancel() }
        }
        func documentPickerWasCancelled(_ c: UIDocumentPickerViewController) { parent.onCancel() }
    }
}
