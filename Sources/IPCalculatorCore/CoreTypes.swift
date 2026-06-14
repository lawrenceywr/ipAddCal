import Foundation

public enum IPVersion: Int, Sendable {
    case v4 = 4
    case v6 = 6
}

public enum NumberBase: Sendable {
    case binary
    case decimal
    case hexadecimal
}
