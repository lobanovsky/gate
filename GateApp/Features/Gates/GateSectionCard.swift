import SwiftUI

struct GateSectionCard: View {
    let section: GateSection
    let isBusy: Bool
    let onTap: (GateDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.title3.weight(.semibold))

            VStack(spacing: 12) {
                actionButton(direction: .enter, title: "Заехать")
                actionButton(direction: .exit, title: "Выехать")
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func actionButton(direction: GateDirection, title: String) -> some View {
        let action = section.actions[direction]

        return Button {
            onTap(direction)
        } label: {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Image(systemName: direction == .enter ? "arrow.down.forward.circle.fill" : "arrow.up.forward.circle.fill")
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(backgroundColor(for: direction))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .disabled(isBusy || action == nil)
        .opacity(action == nil ? 0.55 : 1.0)
    }

    private func backgroundColor(for direction: GateDirection) -> Color {
        switch (section.area, direction) {
        case (.courtyard, .enter):
            return Color(red: 0.08, green: 0.49, blue: 0.83)
        case (.courtyard, .exit):
            return Color(red: 0.16, green: 0.64, blue: 0.49)
        case (.parking, .enter):
            return Color(red: 0.94, green: 0.53, blue: 0.15)
        case (.parking, .exit):
            return Color(red: 0.82, green: 0.28, blue: 0.29)
        }
    }
}
