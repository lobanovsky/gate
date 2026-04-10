import SwiftUI

struct GateSectionCard: View {
    let section: GateSection
    let titleForDirection: (GateDirection) -> String
    let isInProgress: (GateDirection) -> Bool
    let isDisabled: (GateDirection, Bool) -> Bool
    let onCall: (GateDirection) -> Void
    let onTap: (GateDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.title3.weight(.semibold))

            VStack(spacing: 18) {
                actionButton(direction: .enter)
                actionButton(direction: .exit)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func actionButton(direction: GateDirection) -> some View {
        let action = section.actions[direction]
        let isButtonDisabled = isDisabled(direction, action != nil)
        let isProgressVisible = isInProgress(direction)

        return HStack(spacing: 14) {
            Button {
                onCall(direction)
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 74, height: 78)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(buttonFillColor(for: direction, isProgressVisible: false, isUnavailable: false))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                onTap(direction)
            } label: {
                HStack {
                    Text(titleForDirection(direction))
                        .font(.system(size: 22, weight: .bold))

                    Spacer()

                    ZStack {
                        if isProgressVisible {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.3)
                        } else {
                            Image(systemName: direction == .enter ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill")
                                .font(.system(size: 34, weight: .bold))
                        }
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 26)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(buttonFillColor(for: direction, isProgressVisible: isProgressVisible, isUnavailable: isButtonDisabled && action == nil))
            .overlay {
                if isProgressVisible {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.92), lineWidth: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled && action == nil ? 0.52 : (isProgressVisible ? 1.0 : 1.0))
        }
    }

    private func backgroundColor(for direction: GateDirection) -> Color {
        switch direction {
        case .enter:
            return Color(red: 0.66, green: 0.86, blue: 0.61)
        case .exit:
            return Color(red: 0.63, green: 0.82, blue: 0.95)
        }
    }

    private func buttonFillColor(for direction: GateDirection, isProgressVisible: Bool, isUnavailable: Bool) -> Color {
        let base = backgroundColor(for: direction)
        if isUnavailable {
            return base.opacity(0.55)
        }

        if isProgressVisible {
            return Color(red: 0.96, green: 0.73, blue: 0.40)
        }

        return base
    }
}
