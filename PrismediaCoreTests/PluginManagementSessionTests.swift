import XCTest

@testable import PrismediaCore

final class PluginManagementSessionTests: XCTestCase {
    @MainActor
    func testInstallPublishesReturnedProviderInsteadOfOriginalSnapshot() async {
        let available = plugin(installed: false, version: "1.0.0")
        let installed = plugin(installed: true, version: "1.1.0")
        let session = PluginManagementSession(
            plugin: available, service: PluginManagementServiceStub(response: installed))

        let succeeded = await session.install()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(session.plugin, installed)
        XCTAssertFalse(session.isWorking)
    }

    @MainActor
    func testFailedUpdatePreservesStatusAndSuccessfulRetryClearsFailure() async {
        let original = plugin(installed: true, version: "1.0.0")
        let updated = plugin(installed: true, version: "1.1.0")
        let service = PluginManagementServiceStub(response: updated)
        let session = PluginManagementSession(plugin: original, service: service)
        await service.setFailure(URLError(.notConnectedToInternet))

        let failed = await session.update()
        XCTAssertFalse(failed)
        XCTAssertEqual(session.plugin, original)
        XCTAssertNotNil(session.errorMessage)
        await service.setFailure(nil)
        let succeeded = await session.update()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(session.plugin, updated)
        XCTAssertNil(session.errorMessage)
    }

    @MainActor
    func testCredentialRefreshPublishesReadinessAndRetainsItOnRefreshFailure() async {
        let missing = plugin(installed: true, version: "1.0.0", missing: ["api_key"])
        let ready = plugin(installed: true, version: "1.0.0")
        let service = PluginManagementServiceStub(response: ready)
        let session = PluginManagementSession(plugin: missing, service: service)

        await session.refresh()
        XCTAssertEqual(session.plugin, ready)
        await service.setFailure(URLError(.timedOut))
        await session.refresh()

        XCTAssertEqual(session.plugin, ready)
        XCTAssertNotNil(session.refreshError)
        XCTAssertNil(session.errorMessage)
        await service.setFailure(nil)
        await session.refresh()
        XCTAssertNil(session.refreshError)
    }

    @MainActor
    func testRemovalRetryReportsSuccessAfterEarlierFailure() async {
        let original = plugin(installed: true, version: "1.0.0")
        let service = PluginManagementServiceStub(response: original)
        let session = PluginManagementSession(plugin: original, service: service)
        await service.setFailure(URLError(.timedOut))
        let failed = await session.remove()
        XCTAssertFalse(failed)
        await service.setFailure(nil)
        let succeeded = await session.remove()

        XCTAssertTrue(succeeded)
        XCTAssertNil(session.errorMessage)
    }

    @MainActor
    func testCredentialDraftKeepsReplacementWhenRemovalIsUndoneAndSendsOnlyExplicitChanges() async throws {
        var draft = PluginCredentialDraft()
        draft.values = ["api_key": " replacement ", "untouched": "   "]
        draft.setCleared(true, for: "api_key")
        draft.setCleared(false, for: "api_key")
        XCTAssertEqual(draft.values["api_key"], " replacement ")
        draft.setCleared(true, for: "old_secret")
        let service = PluginManagementServiceStub(response: plugin(installed: true, version: "1.0.0"))

        try await PluginAdministrationUseCase(service: service).saveAuth(
            id: "provider", replacements: draft.values, clearedKeys: draft.clearedKeys)

        let values = await service.authValues()
        XCTAssertEqual(values["api_key"], "replacement")
        XCTAssertFalse(values.keys.contains("untouched"))
        XCTAssertTrue(values.keys.contains("old_secret"))
        XCTAssertNil(values["old_secret"]!)
        draft = .init()
        XCTAssertFalse(draft.hasChanges)
    }

    private func plugin(installed: Bool, version: String, missing: [String] = []) -> AdministrativePlugin {
        .init(
            id: "provider", name: "Provider", version: version, installed: installed, enabled: installed,
            isNsfw: false, supports: [], auth: [.init(key: "api_key", label: "API Key", required: true, url: nil)],
            missingAuthKeys: missing, updateAvailable: false, availableVersion: nil)
    }
}
