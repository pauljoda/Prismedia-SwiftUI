import XCTest

@testable import PrismediaCore

final class WebVTTSubtitleParserTests: XCTestCase {
    func testParsesMultilineCuesAndFindsTheActiveCaption() throws {
        let cues = try WebVTTSubtitleParser.parse(
            """
            WEBVTT

            00:00:01.000 --> 00:00:03.500
            First line
            Second line

            00:01:04.250 --> 00:01:06.000 align:start
            Later caption
            """)

        XCTAssertEqual(cues.count, 2)
        XCTAssertEqual(cues[0].text, "First line\nSecond line")
        XCTAssertEqual(cues[1].startTime, 64.25)
        XCTAssertEqual(WebVTTSubtitleParser.activeText(at: 2, cues: cues), "First line\nSecond line")
        XCTAssertNil(WebVTTSubtitleParser.activeText(at: 4, cues: cues))
    }

    func testParsesNestedEmphasisWithoutExposingWebVTTTags() throws {
        let cues = try WebVTTSubtitleParser.parse(
            """
            WEBVTT

            00:00:01.000 --> 00:00:03.500
            This is <i><b>very important</b></i> and <u>underlined</u>.
            """)

        XCTAssertEqual(cues[0].text, "This is very important and underlined.")
        XCTAssertEqual(
            cues[0].content.runs,
            [
                VideoSubtitleTextRun(text: "This is ", style: []),
                VideoSubtitleTextRun(text: "very important", style: [.italic, .bold]),
                VideoSubtitleTextRun(text: " and ", style: []),
                VideoSubtitleTextRun(text: "underlined", style: [.underline]),
                VideoSubtitleTextRun(text: ".", style: []),
            ]
        )
    }

    func testDecodesEntitiesAndRemovesWebVTTAnnotationTags() throws {
        let cues = try WebVTTSubtitleParser.parse(
            """
            WEBVTT

            00:00:01.000 --> 00:00:03.500
            <v Narrator><c.notice>Rock &amp; Roll</c> &lt;forever&gt; <00:00:02.000>
            """)

        XCTAssertEqual(cues[0].text, "Rock & Roll <forever> ")
        XCTAssertFalse(cues[0].text.contains("<v"))
        XCTAssertFalse(cues[0].text.contains("<c"))
    }
}
