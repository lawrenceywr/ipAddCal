import Foundation

public struct ParsedIPAddress: Equatable, Sendable {
    public var version: IPVersion
    public var value: UInt128

    public init(version: IPVersion, value: UInt128) {
        self.version = version
        self.value = value
    }
}

public enum IPAddressFormatter {
    public static func ipv4(_ value: UInt32) -> String {
        [
            String((value >> 24) & 0xff),
            String((value >> 16) & 0xff),
            String((value >> 8) & 0xff),
            String(value & 0xff),
        ].joined(separator: ".")
    }

    public static func ipv6(_ value: UInt128) -> String {
        let groups = (0..<8).map { index in
            UInt16((value >> UInt128((7 - index) * 16)) & 0xffff)
        }
        let run = longestZeroRun(groups)
        var rendered: [String] = []
        var index = 0

        while index < groups.count {
            if run.length >= 2 && index == run.start {
                rendered.append("")
                index += run.length
                if index == groups.count {
                    rendered.append("")
                }
            } else {
                rendered.append(String(groups[index], radix: 16))
                index += 1
            }
        }

        let text = rendered.joined(separator: ":")
        return text.hasPrefix(":") ? ":\(text)" : text
    }

    private static func longestZeroRun(_ groups: [UInt16]) -> (start: Int, length: Int) {
        var best = (start: -1, length: 0)
        var current = (start: -1, length: 0)

        for (index, group) in groups.enumerated() {
            if group == 0 {
                if current.start == -1 {
                    current = (index, 0)
                }
                current.length += 1
                if current.length > best.length {
                    best = current
                }
            } else {
                current = (-1, 0)
            }
        }

        return best
    }
}
