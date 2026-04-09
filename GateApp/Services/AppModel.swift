import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isBusy = false
    @Published private(set) var isLoadingDevices = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var sections: [GateSection] = []
    @Published var alert: AppAlert?
    @Published private var inFlightAction: GateActionID?
    @Published private var cooldownActions: Set<GateActionID> = []

    private let apiClient: APIClient
    private let storage: UserDefaults
    private let sessionKey = "gate.user.session"
    private var session: UserSession?
    private var userDevices: UserDevices?

    init(apiClient: APIClient = APIClient(), storage: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.storage = storage
    }

    func bootstrap() async {
        guard let data = storage.data(forKey: sessionKey) else { return }

        do {
            let savedSession = try JSONDecoder().decode(UserSession.self, from: data)
            session = savedSession
            isAuthenticated = true
            await loadDevices()
        } catch {
            storage.removeObject(forKey: sessionKey)
        }
    }

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            let userSession = try await apiClient.login(credentials: Credentials(email: email, password: password))
            session = userSession
            isAuthenticated = true
            try persistSession(userSession)
            await loadDevices()
        } catch {
            present(error: error, title: "Не удалось войти")
        }
    }

    func loadDevices() async {
        guard let session else { return }

        isLoadingDevices = true
        defer { isLoadingDevices = false }

        do {
            let devices = try await apiClient.fetchDevices(token: session.token)
            userDevices = devices
            sections = GateLayoutBuilder.build(from: devices)
        } catch {
            handleAuthorizedError(error, fallbackTitle: "Не удалось загрузить устройства")
        }
    }

    func open(section area: GateArea, direction: GateDirection) async {
        let actionID = GateActionID(area: area, direction: direction)

        guard
            let session,
            let userDevices,
            let action = sections.first(where: { $0.area == area })?.actions[direction],
            inFlightAction == nil,
            !cooldownActions.contains(actionID)
        else {
            return
        }

        isBusy = true
        inFlightAction = actionID
        defer { isBusy = false }

        do {
            try await apiClient.open(device: action.device, userId: userDevices.userId, token: session.token)
            inFlightAction = nil
            cooldownActions.insert(actionID)

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                self.cooldownActions.remove(actionID)
            }
        } catch {
            inFlightAction = nil
            handleAuthorizedError(error, fallbackTitle: "Не удалось выполнить команду")
        }
    }

    func logout() {
        session = nil
        userDevices = nil
        sections = []
        isAuthenticated = false
        storage.removeObject(forKey: sessionKey)
    }

    private func persistSession(_ session: UserSession) throws {
        let data = try JSONEncoder().encode(session)
        storage.set(data, forKey: sessionKey)
    }

    func buttonTitle(area: GateArea, direction: GateDirection) -> String {
        let actionID = GateActionID(area: area, direction: direction)
        if inFlightAction == actionID || cooldownActions.contains(actionID) {
            return "Открываем..."
        }

        switch direction {
        case .enter:
            return "Заехать"
        case .exit:
            return "Выехать"
        }
    }

    func isActionDisabled(area: GateArea, direction: GateDirection, hasDevice: Bool) -> Bool {
        let actionID = GateActionID(area: area, direction: direction)
        return !hasDevice || inFlightAction == actionID || cooldownActions.contains(actionID)
    }

    private func handleAuthorizedError(_ error: Error, fallbackTitle: String) {
        if case APIError.unauthorized = error {
            logout()
            alert = AppAlert(title: "Сессия истекла", message: APIError.unauthorized.errorDescription ?? "")
            return
        }

        present(error: error, title: fallbackTitle)
    }

    private func present(error: Error, title: String) {
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        alert = AppAlert(title: title, message: description)
    }
}

private extension GateDirection {
    var title: String {
        switch self {
        case .enter:
            return "Заехать"
        case .exit:
            return "Выехать"
        }
    }
}
