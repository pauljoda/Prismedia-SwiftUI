import XCTest

@testable import PrismediaCore

final class PluginSearchFieldPolicyTests: XCTestCase {
    func testEligibleProvidersRequireSearchLookupSchemaAndAvailableAuthentication() {
        let eligible = plugin(
            id: "eligible",
            actions: ["search", "lookup-id"],
            fields: [field("query", type: "text", required: true)]
        )
        let searchOnly = plugin(
            id: "search-only",
            actions: ["search"],
            fields: [field("query", type: "text", required: true)]
        )
        let missingAuthentication = plugin(
            id: "missing-auth",
            actions: ["search", "lookup-id"],
            fields: [field("query", type: "text", required: true)],
            missingAuthKeys: ["token"]
        )
        let noSchema = plugin(id: "no-schema", actions: ["search", "lookup-id"], fields: [])

        let result = PluginSearchFieldPolicy.eligibleProviders(
            [searchOnly, missingAuthentication, noSchema, eligible],
            entityKind: "movie",
            hidesNsfw: false
        )

        XCTAssertEqual(result.map(\.id), ["eligible"])
    }

    func testEligibleProvidersRespectNsfwBoundary() {
        let zulu = plugin(
            id: "zulu", name: "Zulu", actions: ["search", "lookup-id"],
            fields: [field("query", type: "text", required: true)]
        )
        let alpha = plugin(
            id: "alpha", name: "Alpha", actions: ["search", "lookup-id"],
            fields: [field("query", type: "text", required: true)]
        )
        let nsfw = plugin(
            id: "nsfw", name: "Adult", isNsfw: true, actions: ["search", "lookup-id"],
            fields: [field("query", type: "text", required: true)]
        )

        let hidden = PluginSearchFieldPolicy.eligibleProviders(
            [zulu, nsfw, alpha], entityKind: "movie", hidesNsfw: true
        )
        let visible = PluginSearchFieldPolicy.eligibleProviders(
            [zulu, nsfw, alpha], entityKind: "movie", hidesNsfw: false
        )

        XCTAssertEqual(Set(hidden.map(\.id)), ["alpha", "zulu"])
        XCTAssertEqual(Set(visible.map(\.id)), ["alpha", "nsfw", "zulu"])
    }

    func testSeedPreservesKnownValuesAndUsesFirstTextFieldForTitle() {
        let fields = [
            field("year", type: "year", required: false),
            field("seriesTitle", type: "text", required: true),
            field("season", type: "number", required: false),
        ]

        XCTAssertEqual(
            PluginSearchFieldPolicy.seedValues(
                for: fields,
                existing: ["year": "2024", "ignored": "value"],
                title: "  Severance  "
            ),
            ["year": "2024", "seriesTitle": "Severance", "season": ""]
        )
    }

    func testSubmissionTrimsDeclaredValuesAndRequiredValidationRejectsWhitespace() {
        let fields = [
            field("query", type: "text", required: true),
            field("year", type: "year", required: false),
        ]

        XCTAssertFalse(
            PluginSearchFieldPolicy.hasRequiredValues(fields: fields, values: ["query": "  "])
        )
        XCTAssertEqual(
            PluginSearchFieldPolicy.submittedValues(
                fields: fields,
                values: ["query": "  Arrival ", "year": " ", "ignored": "no"]
            ),
            ["query": "Arrival"]
        )
    }

    func testCompatibilityTitlePrefersExactTitleThenFirstPopulatedTextField() {
        let fields = [
            field("seriesTitle", type: "text", required: true),
            field("year", type: "year", required: false),
        ]

        XCTAssertEqual(
            PluginSearchFieldPolicy.compatibilityTitle(
                fields: fields,
                values: ["title": " Exact ", "seriesTitle": "Fallback"],
                fallback: "Original"
            ),
            "Exact"
        )
        XCTAssertEqual(
            PluginSearchFieldPolicy.compatibilityTitle(
                fields: fields,
                values: ["seriesTitle": "  First text  "],
                fallback: "Original"
            ),
            "First text"
        )
    }

    private func field(
        _ key: String,
        type: String,
        required: Bool
    ) -> AdministrativePluginSearchField {
        AdministrativePluginSearchField(
            key: key,
            label: key,
            type: type,
            required: required,
            placeholder: nil,
            help: nil
        )
    }

    private func plugin(
        id: String,
        name: String? = nil,
        isNsfw: Bool = false,
        actions: [String],
        fields: [AdministrativePluginSearchField],
        missingAuthKeys: [String] = []
    ) -> AdministrativePlugin {
        AdministrativePlugin(
            id: id,
            name: name ?? id,
            version: "1.0.0",
            installed: true,
            enabled: true,
            isNsfw: isNsfw,
            supports: [
                AdministrativePluginSupport(
                    entityKind: "movie",
                    actions: actions,
                    search: AdministrativePluginSearchDefinition(fields: fields)
                )
            ],
            missingAuthKeys: missingAuthKeys,
            updateAvailable: false,
            availableVersion: nil
        )
    }
}
