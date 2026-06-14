# IP 地址计算器

一个使用 Tauri v2 和 TypeScript 开发的轻量桌面 IP 地址计算工具。

IP 解析与网段计算逻辑已全部使用 TypeScript 实现，项目不依赖 Python 运行时。

## 功能

- 计算 IPv4 / IPv6 网段、地址数量、首个地址和最后地址
- 支持 CIDR、数字前缀和 IPv4 子网掩码输入
- IPv4 前缀在 `/16` 到 `/24` 时显示 C 段数量
- 根据指定的 IPv6 `/96` 前缀生成对应的 IPv6 网段
- 根据 IPv6 地址或网段的最后 32 位反算 IPv4 地址或网段，可选校验 IPv6 `/96` 前缀
- 点击结果即可复制单项内容
- 支持复制全部结果和历史记录
- 自动处理常见中文输入法标点
- 自定义 Soft Neumorphic Liquid Glass 窗口界面

## 技术栈

- Tauri v2
- TypeScript
- Vite
- Vitest
- Rust

## 本地开发

请先安装：

- Node.js
- Rust 工具链
- Windows 开发需要 Visual Studio Build Tools 和 MSVC 工具链

克隆仓库后安装依赖：

```bash
npm ci
```

仓库仅提交源代码、依赖清单与锁文件、配置文件和必要静态资源。`node_modules/`、`dist/`、`src-tauri/target/`、安装包及其他构建产物不会提交，克隆后需要自行安装依赖。

启动 Tauri 开发模式：

```bash
npm run tauri dev
```

仅启动前端开发服务器：

```bash
npm run dev
```

## 测试与构建

```bash
npm test
npm run build
```

构建 Tauri 应用：

```bash
npm run tauri build
```

构建不带安装包的便携可执行文件：

```bash
npm run portable
```

## 项目结构

```text
src/                  TypeScript 前端和 IP 计算逻辑
public/               前端静态资源
src-tauri/            Tauri 配置、Rust 入口和应用图标
package.json          Node.js 依赖和脚本
package-lock.json     Node.js 锁定依赖版本
src-tauri/Cargo.toml  Rust 依赖
src-tauri/Cargo.lock  Rust 锁定依赖版本
```

## 第三方资源

应用中的 Accounting 图标来自 [Icons8](https://icons8.com/icon/38502/accounting)，不受本仓库 MIT 许可证覆盖；使用时请遵守 [Icons8 License](https://icons8.com/license)。

## License

[MIT](LICENSE)
