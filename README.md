# IP 地址计算器

一个使用 SwiftUI 为 macOS 26 构建的原生 IP 地址计算工具。

## 功能

- 计算 IPv4 / IPv6 网段、地址数量、首个地址和最后地址
- 支持 CIDR、数字前缀和 IPv4 子网掩码输入
- IPv4 前缀在 `/16` 到 `/24` 时显示 C 段数量
- 根据指定的 IPv6 `/96` 前缀生成对应的 IPv6 网段
- 根据 IPv6 地址或网段的最后 32 位反算 IPv4 地址或网段，可选校验 IPv6 `/96` 前缀
- 支持二进制、十进制、十六进制的 32 位无符号整数转换
- 支持点击 32 位二进制位切换数值
- 点击结果即可复制单项内容
- 支持复制全部结果和历史记录
- 自动处理常见中文输入法标点
- 使用 macOS 原生 SwiftUI 和 Liquid Glass 风格界面

## 技术栈

- Swift 6
- SwiftUI
- AppKit
- Swift Package Manager
- Swift Testing

## 本地开发

请先安装 Xcode 26.5 或更新版本。

运行测试：

```bash
swift test
```

构建：

```bash
swift build
```

运行：

```bash
swift run IPNetworkCalculator
```

也可以在 Xcode 中打开本目录的 Swift Package 后运行 `IPNetworkCalculator` target。

## 项目结构

```text
Sources/IPCalculatorCore/       纯 Swift 计算逻辑
Sources/IPCalculatorFeatures/   SwiftUI 状态、结果行、历史和复制文案映射
Sources/IPNetworkCalculator/    SwiftUI macOS 应用入口和界面
Tests/                          Core 和 Feature 测试
Package.swift                   Swift Package 配置
```

## License

[MIT](LICENSE)
