import Foundation

enum VoxCPMError: LocalizedError {
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .server(let m): return m
        case .badResponse: return "服务器返回了无法识别的响应"
        }
    }
}

/// 与后端通信：三个合成接口都返回 WAV 的 Data。
struct VoxCPMClient {
    private func url(_ path: String) -> URL {
        AppConfig.serverBaseURL.appendingPathComponent(path)
    }

    func health() async throws -> Bool {
        var req = URLRequest(url: url("health"))
        req.timeoutInterval = 10
        let (_, resp) = try await URLSession.shared.data(for: req)
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }

    func tts(text: String, cfg: Double, steps: Int, normalize: Bool) async throws -> Data {
        try await postJSON("api/tts", [
            "text": text,
            "cfg_value": cfg,
            "inference_timesteps": steps,
            "normalize": normalize,
        ])
    }

    func design(text: String, description: String, cfg: Double, steps: Int) async throws -> Data {
        try await postJSON("api/design", [
            "text": text,
            "description": description,
            "cfg_value": cfg,
            "inference_timesteps": steps,
        ])
    }

    func clone(text: String, control: String, audioURL: URL, cfg: Double, steps: Int) async throws -> Data {
        var req = URLRequest(url: url("api/clone"))
        req.httpMethod = "POST"
        req.timeoutInterval = 300
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        appendField("text", text)
        appendField("control", control)
        appendField("cfg_value", String(cfg))
        appendField("inference_timesteps", String(steps))

        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"reference_audio\"; filename=\"\(audioURL.lastPathComponent)\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        return try await send(req, uploadBody: body)
    }

    // MARK: - 内部

    private func postJSON(_ path: String, _ payload: [String: Any]) async throws -> Data {
        var req = URLRequest(url: url(path))
        req.httpMethod = "POST"
        req.timeoutInterval = 300
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return try await send(req, uploadBody: nil)
    }

    private func send(_ request: URLRequest, uploadBody: Data?) async throws -> Data {
        let data: Data
        let resp: URLResponse
        if let uploadBody {
            (data, resp) = try await URLSession.shared.upload(for: request, from: uploadBody)
        } else {
            (data, resp) = try await URLSession.shared.data(for: request)
        }
        guard let http = resp as? HTTPURLResponse else { throw VoxCPMError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw VoxCPMError.server(msg)
        }
        return data
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}
