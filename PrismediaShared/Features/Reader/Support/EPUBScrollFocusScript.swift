import Foundation

enum EPUBScrollFocusScript {
    static func install(preferences: EPUBReaderPreferences) -> String {
        """
        (() => {
          const initialConfiguration = \(configuration(preferences));
          if (window.prismediaReadingFocus) {
            window.prismediaReadingFocus.update(initialConfiguration);
            return;
          }

          const blockSelector = "p, li:not(:has(p)), blockquote:not(:has(p)), pre, h1, h2, h3, h4, h5, h6";
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

          const focusTargetY = (viewportCenter) => {
            const firstBlock = blocks[0];
            if (!firstBlock) return viewportCenter;

            const scrollElement = document.scrollingElement ?? document.documentElement;
            const scrollTop = Math.max(0, scrollElement.scrollTop);
            const firstRect = firstBlock.getBoundingClientRect();
            const firstBlockDocumentCenter = (firstRect.top + firstRect.bottom) / 2 + scrollTop;
            return Math.min(
              viewportCenter,
              Math.max(0, firstBlockDocumentCenter + scrollTop)
            );
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

          window.prismediaReadingFocus = {
            update(configuration) {
              state = configuration;
              updateEndSpacer();
              refreshBlocks();
              scheduleFocus();
              settleGuide();
            }
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
