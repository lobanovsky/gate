import Foundation

struct APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(credentials: Credentials) async throws -> UserSession {
        try await request(
            path: "/api/auth/login",
            method: "POST",
            body: credentials,
            token: nil,
            responseType: UserSession.self
        )
    }

    func register(payload: RegistrationPayload) async throws -> RegistrationResponse {
        try await request(
            path: "/api/auth/register",
            method: "POST",
            body: payload,
            token: nil,
            responseType: RegistrationResponse.self
        )
    }

    func recoverPassword(email: String) async throws -> MessageResponse {
        try await request(
            path: "/api/auth/recover-password",
            method: "POST",
            body: RecoverPasswordPayload(email: email),
            token: nil,
            responseType: MessageResponse.self
        )
    }

    func fetchDevices(token: String) async throws -> UserDevices {
        try await request(
            path: "/api/private/devices",
            method: "GET",
            body: Optional<String>.none,
            token: token,
            responseType: UserDevices.self
        )
    }

    func open(device: Device, userId: String, token: String) async throws {
        struct OpenPayload: Encodable {
            let key: String
            let userid: String
        }

        _ = try await request(
            path: "/api/private/devices/\(device.id)/open",
            method: "POST",
            body: OpenPayload(key: device.deviceKey, userid: userId),
            token: token,
            responseType: EmptyResponse.self
        )
    }

    private func request<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        body: RequestBody?,
        token: String?,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        guard let baseURL = AppConfiguration.backendBaseURL else {
            throw APIError.invalidBaseURL
        }

        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appending(path: trimmedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200 ..< 300:
                if ResponseBody.self == EmptyResponse.self {
                    return EmptyResponse() as! ResponseBody
                }
                return try JSONDecoder().decode(ResponseBody.self, from: data)
            case 401, 403:
                throw APIError.unauthorized
            default:
                if
                    let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
                    let message = errorResponse.error ?? errorResponse.message,
                    !message.isEmpty
                {
                    throw APIError.serverError(message)
                }

                throw APIError.serverError("Ошибка сервера: \(httpResponse.statusCode)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }
}

private struct EmptyResponse: Decodable {}
