//
//  LoginRegisterView.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 06.04.24.
//

import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @State private var isLoggingIn = true
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        loginViewModel.email.contains("@") && loginViewModel.password.count >= 6 && !loginViewModel.isLoading
    }

    var body: some View {
        ZStack {
            // The sea fills the top of the screen and fades into deep water behind the form.
            VStack(spacing: 0) {
                SeaSurfaceView(sea: sea, horizon: 0.5)
                    .frame(height: Theme.Hero.surfaceMinHeight)
                    .overlay(LinearGradient(colors: [Theme.OnSea.scrimTop, .clear, Theme.deepCard],
                                            startPoint: .top, endPoint: .bottom))
                Spacer(minLength: 0)
            }
            .background(Theme.deepCard)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xxl) {
                    brand
                        .padding(.top, 72)
                        .appear()

                    formCard
                        .appear(delay: 0.15)

                    Text("Marine data by Open-Meteo")
                        .font(.footnote)
                        .foregroundStyle(Theme.OnSea.secondary)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: Brand

    /// Lit by the device clock: there is no forecast before signing in.
    @State private var sea = SeaState.ambient()
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44

    private var brand: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "water.waves")
                .font(.system(size: 34, weight: .semibold))
                .frame(width: 72, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        )
                )
                .accessibilityHidden(true)

            Text("DeepBlue")
                .font(.system(size: min(titleSize, 72), weight: .bold, design: .rounded))
                .tracking(-0.8)
                .accessibilityAddTraits(.isHeader)

            Text("Dive conditions, plans and checklists\n— all in one place.")
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.OnSea.secondary)
        }
        .foregroundStyle(Theme.OnSea.primary)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
    }

    // MARK: Form

    private var formCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ModeSwitcher(isLoggingIn: $isLoggingIn)

            VStack(alignment: .leading, spacing: 4) {
                Text(isLoggingIn ? "Welcome back" : "Create your account")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(isLoggingIn ? "Sign in to access your dive plans." : "Start planning safer dives today.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: Theme.Spacing.md) {
                InputField(icon: "envelope", isFocused: focusedField == .email) {
                    TextField("Email address", text: $loginViewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                InputField(icon: "lock", isFocused: focusedField == .password) {
                    Group {
                        if showPassword {
                            TextField("Password", text: $loginViewModel.password)
                        } else {
                            SecureField("Password", text: $loginViewModel.password)
                        }
                    }
                    .textContentType(isLoggingIn ? .password : .newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(submit)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }

                if !isLoggingIn {
                    Text("At least 6 characters.")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let error = loginViewModel.authError {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.coral)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button(action: submit) {
                HStack(spacing: Theme.Spacing.sm) {
                    if loginViewModel.isLoading {
                        ProgressView().tint(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(isLoggingIn ? "Sign In" : "Create Account")
                        .contentTransition(.interpolate)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: canSubmit))
            .disabled(!canSubmit)
            .animation(.spring(response: 0.3, dampingFraction: 1), value: loginViewModel.isLoading)
            .sensoryFeedback(.error, trigger: loginViewModel.authError) { _, new in new != nil }

            if isLoggingIn {
                Button("Forgot password?") {
                    loginViewModel.sendPasswordReset()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ocean)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(Theme.surface)
        )
        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 16)
        .animation(.easeInOut(duration: 0.2), value: isLoggingIn)
        .animation(.easeInOut(duration: 0.2), value: loginViewModel.authError)
        .onChange(of: isLoggingIn) { _, _ in loginViewModel.authError = nil }
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        if isLoggingIn {
            loginViewModel.login()
        } else {
            loginViewModel.register()
        }
    }
}

// MARK: - Mode switcher

private struct ModeSwitcher: View {
    @Binding var isLoggingIn: Bool
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            segment("Sign In", selected: isLoggingIn) { isLoggingIn = true }
            segment("Register", selected: !isLoggingIn) { isLoggingIn = false }
        }
        .padding(4)
        .background(Capsule().fill(Theme.surfaceRaised))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
    }

    private func segment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { action() }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        Capsule()
                            .fill(Theme.ocean)
                            .matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input field

private struct InputField<Content: View>: View {
    let icon: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? Theme.ocean : Theme.textTertiary)
                .frame(width: 20)
            content
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(isFocused ? Theme.ocean : Theme.stroke, lineWidth: isFocused ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

struct LoginRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginRegisterView()
            .environmentObject(LoginViewModel())
    }
}
