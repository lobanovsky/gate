import Foundation

struct Credentials: Encodable {
    let email: String
    let password: String
}

struct UserInfo: Codable {
    let id: Int
    let email: String
    let phoneNumber: String?
    let registrationDate: String?
    let isActive: Bool?
}

struct UserSession: Codable {
    let token: String
    let user: UserInfo
}

struct UserDevices: Decodable {
    let userId: String
    let zones: [Zone]
}

struct Zone: Decodable, Identifiable {
    let id: Int
    let name: String
    let devices: [Device]
}

struct Device: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let label: String
    let color: String?
    let phoneNumber: String?
    let deviceKey: String
}

enum GateArea: String, CaseIterable, Identifiable {
    case parking
    case courtyard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .courtyard:
            return "Двор"
        case .parking:
            return "Паркинг"
        }
    }
}

enum GateDirection: Hashable {
    case enter
    case exit
}

struct GateAction: Equatable {
    let direction: GateDirection
    let device: Device
}

struct GateSection: Identifiable, Equatable {
    let area: GateArea
    let actions: [GateDirection: GateAction]

    var id: GateArea { area }
    var title: String { area.title }
}

struct GateActionID: Hashable {
    let area: GateArea
    let direction: GateDirection
}

extension GateActionID {
    var phoneNumber: String {
        switch (area, direction) {
        case (.courtyard, .enter):
            return "+7-903-178-51-52"
        case (.courtyard, .exit):
            return "+7-903-775-86-56"
        case (.parking, .enter):
            return "+7-926-704-96-48‬"
        case (.parking, .exit):
            return "+7-926-704-97-09"
        }
    }

    var telURL: URL? {
        var normalized = phoneNumber.filter { character in
            character.isWholeNumber || character == "+"
        }

        if normalized.first != "+", !normalized.isEmpty {
            normalized = "+" + normalized
        }

        guard !normalized.isEmpty else { return nil }
        return URL(string: "tel:\(normalized)")
    }
}

struct APIErrorResponse: Decodable {
    let error: String?
    let message: String?
}

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

enum APIError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Некорректный URL backend."
        case .invalidResponse:
            return "Сервер вернул неожиданный ответ."
        case .unauthorized:
            return "Сессия истекла. Выполните вход повторно."
        case let .serverError(message):
            return message
        case let .transport(message):
            return message
        }
    }
}
