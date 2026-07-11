import Foundation
import Testing

@Test
func packageScriptBuildsFreshSignedBundleWithIcon() throws {
    let script = try packageScriptSource()

    #expect(script.contains("mktemp -d"))
    #expect(script.contains("Contents/MacOS"))
    #expect(script.contains("Contents/Resources"))
    #expect(script.contains("CFBundleIconFile"))
    #expect(script.contains("LOCAL_ICON=\"${REPO_ROOT}/Resources/AppIcon.icns\""))
    #expect(script.contains("dev-win:src-tauri/icons/icon.ico"))
    #expect(script.contains("sips -s format icns"))
    #expect(script.contains("codesign --force --deep --sign - \"$APP_BUNDLE\""))
}

@Test
func packageScriptReadsProductVersionFromVersionFile() throws {
    let script = try packageScriptSource()
    let version = try String(contentsOf: versionFileURL(), encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)

    #expect(version == "1.0")
    #expect(script.contains("VERSION_FILE=\"${REPO_ROOT}/VERSION\""))
    #expect(script.contains("APP_VERSION=\"$(<\"$VERSION_FILE\")\""))
    #expect(script.contains("BUILD_VERSION=\"$(git rev-list --count HEAD)\""))
    #expect(!script.contains("APP_VERSION=\"0.1.0\""))
    #expect(!script.contains("BUILD_VERSION=\"1\""))
}

@Test
func packageScriptReplacesInstalledBundleWithoutLeavingStaleFiles() throws {
    let script = try packageScriptSource()

    #expect(script.contains("replace_installed_app()"))
    #expect(script.contains("mv \"$INSTALL_PATH\" \"$BACKUP_PATH\""))
    #expect(script.contains("ditto \"$APP_BUNDLE\" \"$INSTALL_PATH\""))
    #expect(script.contains("rm -rf \"$BACKUP_PATH\""))
    #expect(!script.contains("cp .build/release/IPNetworkCalculator /Applications"))
}

@Test
func packageScriptProvidesInstallAndPackagingModes() throws {
    let scriptPath = packageScriptURL()
    let process = Process()
    let output = Pipe()

    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptPath.path, "--help"]
    process.standardOutput = output
    process.standardError = output

    try process.run()
    process.waitUntilExit()

    let helpText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    #expect(process.terminationStatus == 0)
    #expect(helpText.contains("--install"))
    #expect(helpText.contains("--app-path"))
    #expect(helpText.contains("--skip-tests"))
}

private func packageScriptSource() throws -> String {
    try String(contentsOf: packageScriptURL(), encoding: .utf8)
}

private func packageScriptURL() -> URL {
    packageRootURL().appending(path: "scripts/package-app.sh")
}

private func versionFileURL() -> URL {
    packageRootURL().appending(path: "VERSION")
}

private func packageRootURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}
