import SwiftUI

struct GatesView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Быстрый доступ")
                .font(.system(size: 28, weight: .bold))

            Text("Две зоны и четыре действия. Кнопки привязываются к устройствам, загруженным из backend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

