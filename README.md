# IP 地址计算器

[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![License](https://img.shields.io/github/license/lawrenceywr/ipAddCal)](LICENSE)

中文 | [English](README.en.md)

一个面向 macOS 的原生 IP 地址计算工具，使用 SwiftUI + AppKit 构建，专注于 IPv4 / IPv6 网段计算、IPv4/IPv6 映射和 32 位进制转换。

## 特性

- IPv4 / IPv6 网段计算：网段、地址数量、首个地址、最后地址
- 支持 CIDR、数字前缀和 IPv4 子网掩码输入
- IPv4 `/16` 到 `/24` 自动显示 C 段数量
- IPv4 网段映射为指定 IPv6 `/96` 前缀下的 IPv6 网段
- 根据 IPv6 地址或网段的后 32 位反算 IPv4 地址或网段
- 32 位无符号整数的二进制、十进制、十六进制互转
- 点击 32 位 bit 位直接切换数值
- 点击结果复制单项内容，支持复制全部结果和历史记录
- 自动处理常见中文输入法标点
- 原生 macOS Liquid Glass 风格界面

## 快速开始

要求：

- macOS 26+
- Xcode 26.5+

运行测试：

```bash
swift test
```

直接运行：

```bash
swift run IPNetworkCalculator
```

也可以直接用 Xcode 打开仓库根目录后运行 `IPNetworkCalculator` target。

## 仓库分支

- `main`：当前维护中的原生 SwiftUI macOS 版本
- `dev-win`：重构前的旧版 Tauri / TypeScript 分支，保留作历史和兼容参考

## 项目结构

```text
Sources/IPCalculatorCore/       纯 Swift 计算核心
Sources/IPCalculatorFeatures/   状态、结果映射、历史与复制文案
Sources/IPNetworkCalculator/    SwiftUI + AppKit macOS 应用
Tests/                          Core 与 Feature 测试
Package.swift                   Swift Package 配置
```

## 开发说明

当前仓库以 Swift Package Manager 为主，没有单独的 `.app` / `.dmg` 发布产物配置。日常开发和试用建议直接使用：

```bash
swift build
swift run IPNetworkCalculator
```

## License

[MIT](LICENSE)
