import SwiftUI

struct LoginView: View {

    @StateObject private var vm = LoginViewModel()
    @State private var isTestLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // MARK: Logo
                Text("MYStream")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.bottom, 48)

                // MARK: Felder
                VStack(spacing: 12) {
                    TextField("Benutzername...", text: $vm.username)
                        .textFieldStyle(MYTextFieldStyle())
                        .textContentType(.username)
                        .usernameTextInputBehavior()

                    SecureField("Passwort...", text: $vm.password)
                        .textFieldStyle(MYTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal, 32)

                // MARK: Fehlermeldung
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                // MARK: Login Button
                Button {
                    Task { await vm.login() }
                } label: {
                    Group {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Login")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .disabled(vm.isLoading)

                // MARK: Test Button
                Button {
                    Task {
                        isTestLoading = true
                        await vm.loginAsGuest()
                        isTestLoading = false
                    }
                } label: {
                    Group {
                        if isTestLoading {
                            ProgressView().tint(.gray)
                        } else {
                            Text("Testmodus")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)
                .disabled(isTestLoading)

                Spacer()
            }
        }
    }
}

// MARK: - Text Input Behavior
private extension View {
    @ViewBuilder
    func usernameTextInputBehavior() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        #else
        self
            .autocorrectionDisabled(true)
        #endif
    }
}

// MARK: - Custom TextField Style
struct MYTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}
