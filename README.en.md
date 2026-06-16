# IP Address Calculator

[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![License](https://img.shields.io/github/license/lawrenceywr/ipAddCal)](LICENSE)

[中文](README.md) | English

A native macOS IP address calculator built with SwiftUI + AppKit, focused on IPv4 / IPv6 network calculation, IPv4/IPv6 mapping, and 32-bit base conversion.

## Features

- IPv4 / IPv6 network calculation: network, address count, first address, and last address
- Supports CIDR, numeric prefixes, and IPv4 subnet masks
- Automatically shows class C segment count for IPv4 `/16` to `/24`
- Maps an IPv4 network into an IPv6 network under a chosen IPv6 `/96` prefix
- Reconstructs IPv4 addresses or networks from the low 32 bits of an IPv6 address or network
- Converts 32-bit unsigned integers between binary, decimal, and hexadecimal
- Toggles individual bits directly in the 32-bit bit grid
- Copies individual result values, full result sets, and history entries
- Normalizes common Chinese IME punctuation automatically
- Uses a native macOS Liquid Glass style interface

## Quick Start

Requirements:

- macOS 26+
- Xcode 26.5+

Run tests:

```bash
swift test
```

Run the app:

```bash
swift run IPNetworkCalculator
```

You can also open the repository root in Xcode and run the `IPNetworkCalculator` target directly.

## Branches

- `main`: current native SwiftUI macOS version
- `dev-win`: legacy Tauri / TypeScript branch kept for history and compatibility reference

## Project Structure

```text
Sources/IPCalculatorCore/       Pure Swift calculation core
Sources/IPCalculatorFeatures/   State, result mapping, history, and copy text
Sources/IPNetworkCalculator/    SwiftUI + AppKit macOS app
Tests/                          Core and Feature tests
Package.swift                   Swift Package configuration
```

## Development Notes

This repository currently focuses on the Swift Package workflow and does not yet include a packaged `.app` or `.dmg` release pipeline. For local development and testing, use:

```bash
swift build
swift run IPNetworkCalculator
```

## License

[MIT](LICENSE)
