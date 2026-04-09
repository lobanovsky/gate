import Foundation

enum GateLayoutBuilder {
    static func build(from userDevices: UserDevices) -> [GateSection] {
        GateArea.allCases.map { area in
            let zone = bestZone(for: area, zones: userDevices.zones)
            let actions = buildActions(from: zone)
            return GateSection(area: area, actions: actions)
        }
    }

    private static func bestZone(for area: GateArea, zones: [Zone]) -> Zone? {
        let ranked = zones.map { zone in
            (zone, score(for: area, zoneName: zone.name))
        }

        return ranked
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.id < rhs.0.id
                }
                return lhs.1 > rhs.1
            }
            .first(where: { $0.1 > 0 })?
            .0
    }

    private static func buildActions(from zone: Zone?) -> [GateDirection: GateAction] {
        guard let zone else { return [:] }

        let devices = zone.devices
        var actions: [GateDirection: GateAction] = [:]

        if let enterDevice = firstMatchingDevice(in: devices, keywords: ["заех", "въезд", "въез", "enter", "in"]) {
            actions[.enter] = GateAction(direction: .enter, device: enterDevice)
        }

        if let exitDevice = firstMatchingDevice(in: devices, keywords: ["выех", "выезд", "exit", "out"]) {
            actions[.exit] = GateAction(direction: .exit, device: exitDevice)
        }

        let unused = devices.filter { device in
            !actions.values.contains(where: { $0.device == device })
        }

        if actions[.enter] == nil, let fallback = unused.first {
            actions[.enter] = GateAction(direction: .enter, device: fallback)
        }

        let remaining = devices.filter { device in
            !actions.values.contains(where: { $0.device == device })
        }

        if actions[.exit] == nil, let fallback = remaining.first {
            actions[.exit] = GateAction(direction: .exit, device: fallback)
        }

        return actions
    }

    private static func score(for area: GateArea, zoneName: String) -> Int {
        let name = normalized(zoneName)

        switch area {
        case .courtyard:
            return score(name: name, keywords: ["двор", "террит", "шлагбаум"])
        case .parking:
            return score(name: name, keywords: ["паркинг", "гараж", "ворота"])
        }
    }

    private static func score(name: String, keywords: [String]) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (name.contains(keyword) ? 1 : 0)
        }
    }

    private static func firstMatchingDevice(in devices: [Device], keywords: [String]) -> Device? {
        devices.first { device in
            let haystack = normalized(device.name + " " + device.label)
            return keywords.contains(where: { haystack.contains($0) })
        }
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased()
    }
}

