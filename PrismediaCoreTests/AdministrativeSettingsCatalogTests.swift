import XCTest

@testable import PrismediaCore

final class AdministrativeSettingsCatalogTests: XCTestCase {
    func testDecodesStringListsAndSettingConstraints() throws {
        let data = Data(
            #"{"groups":[{"key":"subtitles","label":"Subtitles","description":"Caption defaults","order":1,"settings":[{"key":"subtitles.preferredLanguages","groupKey":"subtitles","label":"Preferred languages","description":"Language priority","type":"stringList","value":["en","eng"],"defaultValue":["en"],"isDefault":false,"order":1,"constraints":{"minItems":1,"maxItems":3},"options":[],"inputKind":null,"applyHint":null}]}]}"#
                .utf8
        )

        let catalog = try JSONDecoder().decode(AdministrativeSettingsCatalog.self, from: data)
        let setting = try XCTUnwrap(catalog.groups.first?.settings.first)

        XCTAssertEqual(setting.value, .stringList(["en", "eng"]))
        XCTAssertEqual(setting.value.stringListValue, ["en", "eng"])
        XCTAssertEqual(setting.constraints?.minItems, 1)
        XCTAssertEqual(setting.constraints?.maxItems, 3)
        XCTAssertEqual(setting.controlKind, .stringList)
    }

    func testDecodesNumericConstraintsAndSelectControl() throws {
        let data = Data(
            #"{"key":"subtitles.style","groupKey":"subtitles","label":"Style","description":"Caption style","type":"select","value":"outline","defaultValue":"stylized","isDefault":false,"order":1,"constraints":{"min":0.5,"max":2,"step":0.05},"options":[{"value":"outline","label":"Outline","description":null}],"inputKind":null,"applyHint":null}"#
                .utf8
        )

        let setting = try JSONDecoder().decode(AdministrativeSetting.self, from: data)

        XCTAssertEqual(setting.constraints?.minimum, 0.5)
        XCTAssertEqual(setting.constraints?.maximum, 2)
        XCTAssertEqual(setting.constraints?.step, 0.05)
        XCTAssertEqual(setting.controlKind, .select)
        XCTAssertEqual(setting.value.stringValue, "outline")
    }

    func testAutoIdentifyKindsUseTheFixedNativeSelectionCatalog() throws {
        let setting = try decodeSetting(
            key: "autoIdentify.entityKinds",
            value: #"["video","book"]"#
        )

        let options = AdministrativeStringListOptionCatalog.options(for: setting, plugins: [])

        XCTAssertEqual(options.map(\.value), ["movie", "video", "gallery", "image", "audio", "book"])
        XCTAssertEqual(options.map(\.label), ["Movies", "Videos", "Galleries", "Images", "Audio", "Books"])
    }

    func testAutoIdentifyProviderOptionsIncludeOnlyInstalledEnabledPlugins() throws {
        let setting = try decodeSetting(
            key: "autoIdentify.providers",
            value: #"["tmdb"]"#
        )
        let plugins = [
            plugin(id: "disabled", name: "Disabled", installed: true, enabled: false),
            plugin(id: "missing", name: "Missing", installed: false, enabled: true),
            plugin(id: "tmdb", name: "The Movie Database", installed: true, enabled: true),
        ]

        let options = AdministrativeStringListOptionCatalog.options(for: setting, plugins: plugins)

        XCTAssertEqual(options.map(\.value), ["tmdb"])
        XCTAssertEqual(options.map(\.label), ["The Movie Database"])
    }

    private func decodeSetting(key: String, value: String) throws -> AdministrativeSetting {
        let data = Data(
            """
            {"key":"\(key)","groupKey":"autoIdentify","label":"Selection","description":"Description","type":"stringList","value":\(value),"defaultValue":[],"isDefault":false,"order":1,"constraints":null,"options":[],"inputKind":null,"applyHint":null}
            """.utf8
        )
        return try JSONDecoder().decode(AdministrativeSetting.self, from: data)
    }

    private func plugin(
        id: String,
        name: String,
        installed: Bool,
        enabled: Bool
    ) -> AdministrativePlugin {
        AdministrativePlugin(
            id: id,
            name: name,
            version: "1.0.0",
            installed: installed,
            enabled: enabled,
            isNsfw: false,
            supports: [],
            missingAuthKeys: [],
            updateAvailable: false,
            availableVersion: nil
        )
    }
}
