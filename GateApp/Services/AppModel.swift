import Combine
import Foundation
import LocalAuthentication
import Security

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isBusy = false
    @Published private(set) var isLoadingDevices = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var sections: [GateSection] = []
    @Published private(set) var biometricOption: BiometricOption?
    @Published var alert: AppAlert?
    @Published private var inFlightAction: GateActionID?
    @Published private var cooldownActions: Set<GateActionID> = []

    private let apiClient: APIClient
    private let storage: UserDefaults
    private let credentialsStore: CredentialsStore
    private let biometricAuth: BiometricAuth
    private let sessionKey = "gate.user.session"
    private var session: UserSession?
    private var userDevices: UserDevices?

    init(
        apiClient: APIClient = APIClient(),
        storage: UserDefaults = .standard,
        credentialsStore: CredentialsStore = CredentialsStore(),
        biometricAuth: BiometricAuth = BiometricAuth()
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.credentialsStore = credentialsStore
        self.biometricAuth = biometricAuth
        self.biometricOption = biometricAuth.currentOption(isCredentialStored: credentialsStore.hasCredentials)
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

    func login(email: String, password: String) async -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }

        isBusy = true
        defer { isBusy = false }

        do {
            let userSession = try await apiClient.login(credentials: Credentials(email: email, password: password))
            try applySession(userSession)
            try? credentialsStore.save(credentials: Credentials(email: email, password: password))
            refreshBiometricOption()
            await loadDevices()
            return true
        } catch {
            present(error: error, title: "Не удалось войти")
            return false
        }
    }

    func register(email: String, phoneNumber: String) async -> Bool {
        guard !email.isEmpty, !phoneNumber.isEmpty else { return false }

        isBusy = true
        defer { isBusy = false }

        do {
            let response = try await apiClient.register(payload: RegistrationPayload(email: email, phoneNumber: phoneNumber))
            let userSession = try await apiClient.login(credentials: Credentials(email: email, password: response.password))
            try applySession(userSession)
            try? credentialsStore.save(credentials: Credentials(email: email, password: response.password))
            refreshBiometricOption()
            await loadDevices()
            return true
        } catch {
            present(error: error, title: "Не удалось зарегистрироваться")
            return false
        }
    }

    func loginWithBiometrics() async -> Bool {
        guard let option = biometricOption else {
            presentBiometricError("Биометрический вход недоступен.")
            return false
        }

        isBusy = true
        defer { isBusy = false }

        do {
            try await biometricAuth.authenticate(reason: option.reason)
            let credentials = try credentialsStore.loadCredentials()
            let userSession = try await apiClient.login(credentials: credentials)
            try applySession(userSession)
            await loadDevices()
            return true
        } catch let error as BiometricAuthError {
            if error.shouldPresent {
                presentBiometricError(error.errorDescription ?? "Не удалось использовать биометрию.")
            }
            return false
        } catch let error as CredentialsStoreError {
            presentBiometricError(error.errorDescription ?? "Не удалось получить сохранённые данные для входа.")
            refreshBiometricOption()
            return false
        } catch {
            present(error: error, title: "Не удалось войти")
            return false
        }
    }

    func recoverPassword(email: String) async -> Bool {
        guard !email.isEmpty else { return false }

        isBusy = true
        defer { isBusy = false }

        do {
            let response = try await apiClient.recoverPassword(email: email)
            let message = response.message ?? "Пароль отправлен на \"\(email)\""
            alert = AppAlert(title: "Готово", message: message)
            return true
        } catch {
            present(error: error, title: "Не удалось восстановить пароль")
            return false
        }
    }

    func loadDevices() async {
        guard let session, !isLoadingDevices else { return }

        isLoadingDevices = true
        defer { isLoadingDevices = false }

        do {
            let devices = try await apiClient.fetchDevices(token: session.token)
            userDevices = devices
            sections = GateLayoutBuilder.build(from: devices)
        } catch is CancellationError {
            return
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
        refreshBiometricOption()
    }

    private func persistSession(_ session: UserSession) throws {
        let data = try JSONEncoder().encode(session)
        storage.set(data, forKey: sessionKey)
    }

    private func applySession(_ session: UserSession) throws {
        self.session = session
        isAuthenticated = true
        try persistSession(session)
    }

    private func refreshBiometricOption() {
        biometricOption = biometricAuth.currentOption(isCredentialStored: credentialsStore.hasCredentials)
    }

    func buttonTitle(area: GateArea, direction: GateDirection) -> String {
        let actionID = GateActionID(area: area, direction: direction)
        if inFlightAction == actionID || cooldownActions.contains(actionID) {
            return "Ждите..."
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

    func isActionInProgress(area: GateArea, direction: GateDirection) -> Bool {
        let actionID = GateActionID(area: area, direction: direction)
        return inFlightAction == actionID || cooldownActions.contains(actionID)
    }

    func phoneURL(area: GateArea, direction: GateDirection) -> URL? {
        GateActionID(area: area, direction: direction).telURL
    }

    func presentCallError() {
        alert = AppAlert(title: "Не удалось начать звонок", message: "Проверьте, доступен ли телефонный вызов на этом устройстве.")
    }

    private func presentBiometricError(_ message: String) {
        alert = AppAlert(title: "Не удалось войти по биометрии", message: message)
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

private struct StoredCredentials: Codable {
    let email: String
    let password: String
}

private enum CredentialsStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)
    case noCredentials
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus:
            return "Не удалось сохранить данные для Face ID."
        case .noCredentials:
            return "Сохранённые данные для входа не найдены."
        case .invalidPayload:
            return "Сохранённые данные для входа повреждены."
        }
    }
}

struct CredentialsStore {
    private let service = "ru.housekpr.gate.credentials"
    private let account = "default-user"

    var hasCredentials: Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    func save(credentials: Credentials) throws {
        let payload = StoredCredentials(email: credentials.email, password: credentials.password)
        let data = try JSONEncoder().encode(payload)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw CredentialsStoreError.unexpectedStatus(updateStatus)
        }

        var addQuery = baseQuery
        attributes.forEach { addQuery[$0.key] = $0.value }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CredentialsStoreError.unexpectedStatus(addStatus)
        }
    }

    func loadCredentials() throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw CredentialsStoreError.noCredentials
        }
        guard status == errSecSuccess else {
            throw CredentialsStoreError.unexpectedStatus(status)
        }
        guard
            let data = item as? Data,
            let payload = try? JSONDecoder().decode(StoredCredentials.self, from: data)
        else {
            throw CredentialsStoreError.invalidPayload
        }

        return Credentials(email: payload.email, password: payload.password)
    }
}

struct BiometricOption: Equatable {
    let buttonTitle: String
    let iconName: String
    let reason: String
}

private enum BiometricAuthError: LocalizedError {
    case unavailable
    case cancelled
    case failed(String)

    var shouldPresent: Bool {
        switch self {
        case .cancelled:
            return false
        case .unavailable, .failed:
            return true
        }
    }

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Face ID или Touch ID недоступен на этом устройстве."
        case .cancelled:
            return nil
        case let .failed(message):
            return message
        }
    }
}

struct BiometricAuth {
    func currentOption(isCredentialStored: Bool) -> BiometricOption? {
        guard isCredentialStored else { return nil }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return nil
        }

        switch context.biometryType {
        case .faceID:
            return BiometricOption(
                buttonTitle: "Войти с Face ID",
                iconName: "faceid",
                reason: "Подтвердите вход в приложение через Face ID."
            )
        case .touchID:
            return BiometricOption(
                buttonTitle: "Войти с Touch ID",
                iconName: "touchid",
                reason: "Подтвердите вход в приложение через Touch ID."
            )
        default:
            return nil
        }
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.unavailable
        }

        do {
            _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricAuthError.cancelled
            default:
                throw BiometricAuthError.failed(authError.localizedDescription)
            }
        } catch {
            throw BiometricAuthError.failed(error.localizedDescription)
        }
    }
}
