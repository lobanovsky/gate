import Foundation

enum AppConfiguration {
    static var backendBaseURL: URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String,
            !rawValue.isEmpty
        else {
            return nil
        }

        return URL(string: "https://\(rawValue)")
    }
}

