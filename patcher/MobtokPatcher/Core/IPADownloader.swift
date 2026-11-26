import Foundation

/// Загрузка IPA по прямой ссылке пользователя, с прогрессом и отменой.
/// Файл сразу проверяется: это должен быть zip с Payload/*.app.
@MainActor
final class IPADownloader: NSObject, ObservableObject {
    @Published private(set) var progress: Double = 0
    @Published private(set) var status = ""
    @Published private(set) var isRunning = false

    private var task: URLSessionDownloadTask?
    private var continuation: CheckedContinuation<URL, Error>?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    func download(_ url: URL) async throws -> URL {
        cancel()
        isRunning = true; progress = 0; status = "Подключение…"
        defer { isRunning = false }
        return try await withCheckedThrowingContinuation { c in
            continuation = c
            task = session.downloadTask(with: url)
            task?.resume()
        }
    }

    func cancel() {
        task?.cancel(); task = nil
        continuation?.resume(throwing: CancellationError()); continuation = nil
    }

    fileprivate func finish(_ r: Result<URL, Error>) {
        continuation?.resume(with: r); continuation = nil; task = nil
    }
}

extension IPADownloader: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ s: URLSession, downloadTask: URLSessionDownloadTask,
                                didWriteData _: Int64, totalBytesWritten done: Int64, totalBytesExpectedToWrite total: Int64) {
        Task { @MainActor in
            let mb = { (b: Int64) in String(format: "%.0f МБ", Double(b) / 1_048_576) }
            if total > 0 { progress = Double(done) / Double(total); status = "\(mb(done)) из \(mb(total))" }
            else { status = mb(done) }
        }
    }

    nonisolated func urlSession(_ s: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo loc: URL) {
        let dst = FileManager.default.temporaryDirectory.appendingPathComponent("download-\(UUID().uuidString).ipa")
        let result: Result<URL, Error>
        do {
            if let http = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw PatchError("Сервер ответил \(http.statusCode)")
            }
            try FileManager.default.moveItem(at: loc, to: dst)
            let head = try FileHandle(forReadingFrom: dst).read(upToCount: 4) ?? Data()
            guard head.starts(with: [0x50, 0x4B, 0x03, 0x04]) else {   // "PK\3\4" — zip
                throw PatchError("По ссылке не IPA. Нужна прямая ссылка на файл.")
            }
            result = .success(dst)
        } catch { result = .failure(error) }
        Task { @MainActor in finish(result) }
    }

    nonisolated func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, (error as NSError).code != NSURLErrorCancelled else { return }
        Task { @MainActor in finish(.failure(error)) }
    }
}
