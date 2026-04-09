import SwiftUI

struct GateSectionCard: View {
    let section: GateSection
    let titleForDirection: (GateDirection) -> String
    let isDisabled: (GateDirection, Bool) -> Bool
    let onTap: (GateDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.title3.weight(.semibold))

            VStack(spacing: 12) {
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

        return Button {
            onTap(direction)
        } label: {
            HStack {
                Text(titleForDirection(direction))
                    .font(.headline)

                Spacer()

                Image(systemName: direction == .enter ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill")
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(backgroundColor(for: direction))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled && action == nil ? 0.55 : (isButtonDisabled ? 0.72 : 1.0))
    }

    private func backgroundColor(for direction: GateDirection) -> Color {
        switch direction {
        case .enter:
            return Color(red: 0.66, green: 0.86, blue: 0.61)
        case .exit:
            return Color(red: 0.63, green: 0.82, blue: 0.95)
        }
    }
}
