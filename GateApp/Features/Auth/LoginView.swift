import SwiftUI

private enum AuthScreenMode {
    case login
    case register
    case resetPassword
}

struct LoginView: View {
    @EnvironmentObject private var appModel: AppModel

    @State private var mode: AuthScreenMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var registrationEmail = ""
    @State private var registrationPhone = ""
    @State private var recoveryEmail = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Шлагбаумы на Марьиной роще")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text("Управление шлагбаумами и воротами с любовью к деталям")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Group {
                switch mode {
                case .login:
                    loginForm
                case .register:
                    registrationForm
                case .resetPassword:
                    recoveryForm
                }
            }

            Spacer()
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.94, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private var loginForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authFieldStyle()

            SecureField("Пароль", text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authFieldStyle()

            Button {
                Task {
                    _ = await appModel.login(email: email, password: password)
                }
            } label: {
                actionLabel(title: "Войти")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.isBusy || email.isEmpty || password.isEmpty)

            VStack(spacing: 10) {
                Button("Регистрация") {
                    mode = .register
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Button("Забыли пароль?") {
                    recoveryEmail = email
                    mode = .resetPassword
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private var registrationForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $registrationEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authFieldStyle()

            TextField("Номер телефона", text: registrationPhoneBinding)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authFieldStyle()

            Button {
                Task {
                    _ = await appModel.register(
                        email: registrationEmail,
                        phoneNumber: registrationPhone.replacingOccurrences(of: " ", with: "")
                    )
                }
            } label: {
                actionLabel(title: "Зарегистрироваться")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.isBusy || !isValidEmail(registrationEmail) || !isValidRussianPhone(registrationPhone))

            Button("Уже есть учётная запись? Войти") {
                email = registrationEmail
                mode = .login
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private var recoveryForm: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $recoveryEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authFieldStyle()

            Button {
                Task {
                    let isSuccess = await appModel.recoverPassword(email: recoveryEmail)
                    if isSuccess {
                        email = recoveryEmail
                        mode = .login
                    }
                }
            } label: {
                actionLabel(title: "Отправить")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.isBusy || !isValidEmail(recoveryEmail))

            Button("Вернуться на форму входа") {
                email = recoveryEmail
                mode = .login
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .font(.footnote)
            .padding(.top, 4)
        }
    }

    private var registrationPhoneBinding: Binding<String> {
        Binding(
            get: { registrationPhone },
            set: { newValue in
                registrationPhone = formatRussianPhone(newValue)
            }
        )
    }

    @ViewBuilder
    private func actionLabel(title: String) -> some View {
        HStack {
            if appModel.isBusy {
                ProgressView()
                    .tint(.white)
            }
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    private func isValidRussianPhone(_ value: String) -> Bool {
        let digits = value.filter(\.isWholeNumber)
        return digits.count == 11 && digits.first == "7"
    }

    private func formatRussianPhone(_ value: String) -> String {
        var digits = value.filter(\.isWholeNumber)

        guard !digits.isEmpty else { return "" }

        if digits.hasPrefix("8") {
            digits.removeFirst()
            digits = "7" + digits
        } else if !digits.hasPrefix("7") {
            digits = "7" + digits
        }

        digits = String(digits.prefix(11))
        let numbers = String(digits.dropFirst())

        var result = "+7"
        if !numbers.isEmpty {
            result += "("
            result += String(numbers.prefix(3))
        }
        if numbers.count >= 3 {
            result += ")"
        }
        if numbers.count > 3 {
            let start = numbers.index(numbers.startIndex, offsetBy: 3)
            let end = numbers.index(start, offsetBy: min(3, numbers.distance(from: start, to: numbers.endIndex)))
            result += " " + numbers[start..<end]
        }
        if numbers.count > 6 {
            let start = numbers.index(numbers.startIndex, offsetBy: 6)
            let end = numbers.index(start, offsetBy: min(2, numbers.distance(from: start, to: numbers.endIndex)))
            result += " " + numbers[start..<end]
        }
        if numbers.count > 8 {
            let start = numbers.index(numbers.startIndex, offsetBy: 8)
            let end = numbers.index(start, offsetBy: min(2, numbers.distance(from: start, to: numbers.endIndex)))
            result += " " + numbers[start..<end]
        }

        return result
    }
}

private extension View {
    func authFieldStyle() -> some View {
        padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
