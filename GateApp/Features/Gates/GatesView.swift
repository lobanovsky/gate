import SwiftUI

struct GatesView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if appModel.isLoadingDevices && appModel.sections.isEmpty {
                    ProgressView("Загружаем устройства")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ForEach(appModel.sections) { section in
                        GateSectionCard(
                            section: section,
                            isBusy: appModel.isBusy,
                            onTap: { direction in
                                Task {
                                    await appModel.open(section: section.area, direction: direction)
                                }
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Управление")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Выйти") {
                    appModel.logout()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await appModel.loadDevices()
                    }
                } label: {
                    if appModel.isLoadingDevices {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(appModel.isBusy)
            }
        }
        .refreshable {
            await appModel.loadDevices()
        }
    }
}
