import Foundation

/// JavaScript installed in every EPUB chapter for the scroll reading focus and exact paragraph
/// positions. The script measures paragraph geometry; restore and capture share its rules:
/// paged chapters anchor the first paragraph that starts on the visible page, and scrolled
/// chapters anchor the paragraph whose start sits nearest above the focus line.
enum EPUBScrollFocusScript {
    // MARK: - Static Variables

    /// Measures the paragraph at the reading position as `EPUBParagraphViewport` JSON.
    static let currentParagraphViewport =
        "JSON.stringify(window.prismediaReadingFocus?.currentPosition?.() ?? null);"

    // MARK: - Actions - Scripts

    static func install(preferences: EPUBReaderPreferences) -> String {
        """
        (() => {
          const initialConfiguration = \(configuration(preferences));
          if (window.prismediaReadingFocus) {
            window.prismediaReadingFocus.update(initialConfiguration);
            return;
          }

          const blockSelector = "p, li:not(:has(p)), blockquote:not(:has(p)), pre, h1, h2, h3, h4, h5, h6";
          const maximumAnchorTextLength = 512;
          const pageEdgeTolerance = 1;
          const focusLineTolerance = 4;
          const originalOpacity = new WeakMap();
          let blocks = [];
          let endSpacer = null;
          let guide = null;
          let guideTimer = null;
          let frameRequest = null;
          let state = initialConfiguration;

          const rememberOpacity = (element) => {
            if (originalOpacity.has(element)) return;
            originalOpacity.set(element, {
              value: element.style.getPropertyValue("opacity"),
              priority: element.style.getPropertyPriority("opacity")
            });
          };

          const restoreOpacity = (element) => {
            const original = originalOpacity.get(element);
            if (!original || original.value === "") {
              element.style.removeProperty("opacity");
            } else {
              element.style.setProperty("opacity", original.value, original.priority);
            }
          };

          const refreshBlocks = () => {
            blocks = Array.from(document.querySelectorAll(blockSelector));
          };

          const scrollingElement = () => document.scrollingElement ?? document.documentElement;

          const normalizedText = (value) => {
            return typeof value === "string" ? value.replace(/\\s+/g, " ").trim() : "";
          };

          const isPaginated = () => {
            const view = document.documentElement.style.getPropertyValue("--USER__view");
            return view.trim() !== "readium-scroll-on";
          };

          const updateEndSpacer = () => {
            const shouldShow = state.focusEnabled || state.guideEnabled;
            if (!shouldShow) {
              endSpacer?.remove();
              endSpacer = null;
              return;
            }
            if (endSpacer?.isConnected) return;

            endSpacer = document.createElement("div");
            endSpacer.id = "prismedia-reading-focus-end-spacer";
            endSpacer.setAttribute("aria-hidden", "true");
            Object.assign(endSpacer.style, {
              display: "block",
              flex: "0 0 50vh",
              width: "100%",
              height: "50vh",
              minHeight: "50vh",
              margin: "0",
              padding: "0",
              border: "0",
              clear: "both",
              opacity: "0",
              userSelect: "none",
              pointerEvents: "none"
            });
            (document.body ?? document.documentElement).appendChild(endSpacer);
          };

          const firstBlockDocumentCenter = () => {
            const firstBlock = blocks[0];
            if (!firstBlock) return null;
            const scrollTop = Math.max(0, scrollingElement().scrollTop);
            const firstRect = firstBlock.getBoundingClientRect();
            return (firstRect.top + firstRect.bottom) / 2 + scrollTop;
          };

          // The shared focus line, in viewport coordinates. It starts on the first block and
          // moves down to the viewport centre as the reader scrolls into the chapter.
          const focusTargetY = (viewportCenter) => {
            const firstBlockCenter = firstBlockDocumentCenter();
            if (firstBlockCenter === null) return viewportCenter;
            const scrollTop = Math.max(0, scrollingElement().scrollTop);
            return Math.min(
              viewportCenter,
              Math.max(0, firstBlockCenter + scrollTop)
            );
          };

          // Inverts focusTargetY: the scroll offset that places a paragraph start on the focus line.
          const scrollTopPlacingOnFocusLine = (documentTop) => {
            const viewportCenter = window.innerHeight / 2;
            const firstBlockCenter = firstBlockDocumentCenter();
            if (firstBlockCenter === null || documentTop >= 2 * viewportCenter - firstBlockCenter) {
              return Math.max(0, documentTop - viewportCenter);
            }
            return Math.max(0, (documentTop - firstBlockCenter) / 2);
          };

          // The first laid-out fragment of a block is where its paragraph starts.
          const startRect = (element) => {
            for (const rect of element.getClientRects()) {
              if (rect.width > 0 || rect.height > 0) return rect;
            }
            return null;
          };

          const hasReadableText = (element) => normalizedText(element.textContent).length > 0;

          // Paged: the first paragraph whose start lies on the visible page.
          const pagedAnchorElement = () => {
            const pageWidth = window.innerWidth;
            return blocks.find((element) => {
              const rect = startRect(element);
              return rect !== null
                && rect.left >= -pageEdgeTolerance
                && rect.left < pageWidth - pageEdgeTolerance
                && rect.bottom > 0
                && rect.top < window.innerHeight
                && hasReadableText(element);
            }) ?? null;
          };

          // Scrolled: the paragraph whose start is nearest above, or at, the focus line.
          const scrolledAnchorElement = () => {
            const focusLine = focusTargetY(window.innerHeight / 2) + focusLineTolerance;
            let focused = null;
            let focusedTop = -Infinity;
            blocks.forEach((element) => {
              const rect = startRect(element);
              if (rect === null || rect.top > focusLine || rect.top < focusedTop) return;
              if (!hasReadableText(element)) return;
              focused = element;
              focusedTop = rect.top;
            });
            return focused;
          };

          // Anchors keep a trimmed prefix of the paragraph text.
          const anchorText = (element) => {
            return normalizedText(normalizedText(element?.textContent).slice(0, maximumAnchorTextLength));
          };

          const anchorFor = (element) => {
            const text = anchorText(element);
            return {
              index: blocks.indexOf(element),
              text: text.length > 0 ? text : null
            };
          };

          const position = (element) => {
            return {
              anchor: element ? anchorFor(element) : null,
              scrollX: window.scrollX,
              scrollY: window.scrollY
            };
          };

          // Captured anchors hold a truncated prefix; other readers may store the full text.
          const matchesAnchorText = (element, requestedText) => {
            return anchorText(element) === requestedText
              || normalizedText(element?.textContent) === requestedText;
          };

          const anchorElement = (anchor) => {
            const requestedText = normalizedText(anchor?.text);
            const requestedIndex = Number(anchor?.index);
            const indexed = Number.isInteger(requestedIndex) && requestedIndex >= 0
              ? blocks[requestedIndex] ?? null
              : null;
            if (requestedText.length === 0 || (indexed && matchesAnchorText(indexed, requestedText))) {
              return indexed;
            }
            return blocks.find((block) => matchesAnchorText(block, requestedText)) ?? null;
          };

          const measureBlock = (element, focusTarget) => {
            const rect = element.getBoundingClientRect();
            const isVisible = rect.bottom > 0 && rect.top < window.innerHeight;
            const containsFocusTarget = rect.top <= focusTarget && rect.bottom >= focusTarget;
            let distanceFromFocusTarget = 0;
            if (rect.bottom < focusTarget) {
              distanceFromFocusTarget = focusTarget - rect.bottom;
            } else if (rect.top > focusTarget) {
              distanceFromFocusTarget = rect.top - focusTarget;
            }
            return {
              element,
              isVisible,
              containsFocusTarget,
              distanceFromFocusTarget
            };
          };

          const activeMeasurement = (visibleMeasurements) => {
            if (visibleMeasurements.length === 0) return null;

            const containingParagraph = visibleMeasurements.find(({ containsFocusTarget }) => {
              return containsFocusTarget;
            });
            if (containingParagraph) return containingParagraph;

            return visibleMeasurements.reduce((closest, measurement) => {
              return measurement.distanceFromFocusTarget < closest.distanceFromFocusTarget
                ? measurement
                : closest;
            });
          };

          const applyFocus = () => {
            frameRequest = null;
            if (!state.focusEnabled) {
              blocks.forEach(restoreOpacity);
              return;
            }

            const viewportCenter = window.innerHeight / 2;
            const focusTarget = focusTargetY(viewportCenter);
            const fadeRadius = Math.max(140, window.innerHeight * 0.52);
            const minimumOpacity = Math.max(0.2, 1 - state.strength);
            const inactiveCeiling = minimumOpacity + (1 - minimumOpacity) * 0.35;
            const measurements = blocks.map((element) => measureBlock(element, focusTarget));
            const visibleMeasurements = measurements.filter(({ isVisible }) => isVisible);
            const active = activeMeasurement(visibleMeasurements);

            measurements.forEach(({ element, distanceFromFocusTarget }) => {
              rememberOpacity(element);
              let opacity = minimumOpacity;
              if (element === active?.element) {
                opacity = 1;
              } else if (distanceFromFocusTarget < fadeRadius) {
                const progress = distanceFromFocusTarget / fadeRadius;
                opacity = Math.min(
                  inactiveCeiling,
                  1 - progress * (1 - minimumOpacity)
                );
              }
              element.style.setProperty("opacity", opacity.toFixed(3), "important");
            });
          };

          const scheduleFocus = () => {
            if (frameRequest !== null) return;
            frameRequest = window.requestAnimationFrame(applyFocus);
          };

          const ensureGuide = () => {
            if (guide) return guide;
            guide = document.createElement("div");
            guide.id = "prismedia-reading-guide";
            guide.setAttribute("aria-hidden", "true");
            Object.assign(guide.style, {
              position: "fixed",
              zIndex: "2147483647",
              pointerEvents: "none",
              left: "50%",
              top: "calc(50% + 0.7em)",
              width: "min(72ch, calc(100vw - 2rem))",
              borderTop: "1.5px solid currentColor",
              transform: "translateX(-50%)",
              opacity: "0",
              transition: window.matchMedia("(prefers-reduced-motion: reduce)").matches
                ? "none"
                : "opacity 140ms ease-out"
            });
            document.documentElement.appendChild(guide);
            return guide;
          };

          const showGuide = () => {
            const element = ensureGuide();
            element.style.opacity = state.guideEnabled ? "0.38" : "0";
          };

          const settleGuide = () => {
            if (guideTimer !== null) window.clearTimeout(guideTimer);
            guideTimer = window.setTimeout(showGuide, 220);
          };

          const handleScroll = () => {
            if (guide) guide.style.opacity = "0";
            scheduleFocus();
            settleGuide();
          };

          const currentPosition = () => {
            refreshBlocks();
            return position(isPaginated() ? pagedAnchorElement() : scrolledAnchorElement());
          };

          // Paged: turn to the page holding the paragraph start. Scrolled: put the start on the
          // focus line. Either way, measuring again at the landing reports the same paragraph.
          const restoreAnchor = (anchor) => {
            refreshBlocks();
            const target = anchorElement(anchor);
            const rect = target ? startRect(target) : null;
            if (!rect) return null;
            if (isPaginated()) {
              const pageWidth = window.innerWidth;
              if (pageWidth <= 0) return null;
              const documentLeft = rect.left + window.scrollX;
              const pageLeft = Math.floor((documentLeft + pageEdgeTolerance) / pageWidth) * pageWidth;
              scrollingElement().scrollTo({ left: pageLeft, behavior: "instant" });
            } else {
              const top = scrollTopPlacingOnFocusLine(rect.top + window.scrollY);
              scrollingElement().scrollTo({ top, behavior: "instant" });
            }
            scheduleFocus();
            settleGuide();
            return position(target);
          };

          window.prismediaReadingFocus = {
            update(configuration) {
              state = configuration;
              updateEndSpacer();
              refreshBlocks();
              scheduleFocus();
              settleGuide();
            },
            currentPosition,
            restoreAnchor
          };

          window.addEventListener("scroll", handleScroll, { passive: true, capture: true });
          window.addEventListener("resize", handleScroll, { passive: true });
          document.fonts?.ready.then(scheduleFocus);
          window.prismediaReadingFocus.update(initialConfiguration);
        })();
        """
    }

    static func update(preferences: EPUBReaderPreferences) -> String {
        "window.prismediaReadingFocus?.update(\(configuration(preferences)));"
    }

    /// Places `anchor` at the reading position and returns where it landed as
    /// `EPUBParagraphViewport` JSON, or `null` when the paragraph is not in this chapter.
    static func restoreParagraphAnchor(_ anchor: EPUBParagraphAnchor) -> String {
        guard let data = try? JSONEncoder().encode(anchor),
            let json = String(data: data, encoding: .utf8)
        else { return "null;" }
        return "JSON.stringify(window.prismediaReadingFocus?.restoreAnchor?.(\(json)) ?? null);"
    }

    private static func configuration(_ preferences: EPUBReaderPreferences) -> String {
        let isScrollMode = preferences.flow == .scrolled
        let strength = String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            preferences.scrollFocusStrength
        )
        return """
            {
              focusEnabled: \(isScrollMode && preferences.scrollFocusEnabled),
              strength: \(strength),
              guideEnabled: \(isScrollMode && preferences.readingGuideEnabled)
            }
            """
    }
}
