import SwiftUI

struct GatesView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    if appModel.isLoadingDevices && appModel.sections.isEmpty {
                        ProgressView("Загружаем устройства")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(appModel.sections) { section in
                            GateSectionCard(
                                section: section,
                                titleForDirection: { direction in
                                    appModel.buttonTitle(area: section.area, direction: direction)
                                },
                                isDisabled: { direction, hasDevice in
                                    appModel.isActionDisabled(area: section.area, direction: direction, hasDevice: hasDevice)
                                },
                                onCall: { direction in
                                    guard let url = appModel.phoneURL(area: section.area, direction: direction) else {
                                        appModel.presentCallError()
                                        return
                                    }

                                    openURL(url) { accepted in
                                        if !accepted {
                                            appModel.presentCallError()
                                        }
                                    }
                                },
                                onTap: { direction in
                                    Task {
                                        await appModel.open(section: section.area, direction: direction)
                                    }
                                }
                            )
                        }
                    }
                }
                .frame(minHeight: geometry.size.height, alignment: .center)
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Выйти") {
                    appModel.logout()
                }
            }

            ToolbarItem(placement: .principal) {
                Link("Сделано в Бюро Лобановского", destination: URL(string: "https://www.lobanovsky.ru")!)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
