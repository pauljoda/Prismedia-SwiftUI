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
}
