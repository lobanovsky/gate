import XCTest
@testable import Gate

final class GateLayoutBuilderTests: XCTestCase {
    func testBuildMapsCourtyardAndParkingDevices() {
        let devices = UserDevices(
            userId: "42",
            zones: [
                Zone(
                    id: 1,
                    name: "Двор",
                    devices: [
                        Device(id: "1", name: "Двор-заезд", label: "Заехать", color: nil, phoneNumber: nil, deviceKey: "a"),
                        Device(id: "2", name: "Двор-выезд", label: "Выехать", color: nil, phoneNumber: nil, deviceKey: "b")
                    ]
                ),
                Zone(
                    id: 2,
                    name: "Паркинг",
                    devices: [
                        Device(id: "3", name: "Паркинг въезд", label: "Заехать", color: nil, phoneNumber: nil, deviceKey: "c"),
                        Device(id: "4", name: "Паркинг выезд", label: "Выехать", color: nil, phoneNumber: nil, deviceKey: "d")
                    ]
                )
            ]
        )

        let sections = GateLayoutBuilder.build(from: devices)

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections.first(where: { $0.area == .courtyard })?.actions[.enter]?.device.id, "1")
        XCTAssertEqual(sections.first(where: { $0.area == .courtyard })?.actions[.exit]?.device.id, "2")
        XCTAssertEqual(sections.first(where: { $0.area == .parking })?.actions[.enter]?.device.id, "3")
        XCTAssertEqual(sections.first(where: { $0.area == .parking })?.actions[.exit]?.device.id, "4")
    }

    func testBuildFallsBackToDeviceOrderWithoutKeywords() {
        let devices = UserDevices(
            userId: "42",
            zones: [
                Zone(
                    id: 1,
                    name: "Двор",
                    devices: [
                        Device(id: "1", name: "Устройство A", label: "Кнопка 1", color: nil, phoneNumber: nil, deviceKey: "a"),
                        Device(id: "2", name: "Устройство B", label: "Кнопка 2", color: nil, phoneNumber: nil, deviceKey: "b")
                    ]
                )
            ]
        )

        let section = GateLayoutBuilder.build(from: devices).first(where: { $0.area == .courtyard })

        XCTAssertEqual(section?.actions[.enter]?.device.id, "1")
        XCTAssertEqual(section?.actions[.exit]?.device.id, "2")
    }
}
