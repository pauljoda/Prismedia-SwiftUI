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

          const blockSelector = "p, li, blockquote, pre, h1, h2, h3, h4, h5, h6";
          const originalOpacity = new WeakMap();
          let blocks = [];
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
            blocks = Array.from(document.querySelectorAll(blockSelector)).filter((element) => {
              return !element.parentElement?.closest(blockSelector);
            });
          };

          const applyFocus = () => {
            frameRequest = null;
            if (!state.focusEnabled) {
              blocks.forEach(restoreOpacity);
              return;
            }

            const viewportCenter = window.innerHeight / 2;
            const focusRadius = Math.max(56, window.innerHeight * 0.13);
            const fadeRadius = Math.max(focusRadius + 1, window.innerHeight * 0.52);
            const minimumOpacity = Math.max(0.2, 1 - state.strength);
            let closestElement = null;
            let closestDistance = Number.POSITIVE_INFINITY;
            const measurements = [];

            blocks.forEach((element) => {
              const rect = element.getBoundingClientRect();
              const distance = Math.abs((rect.top + rect.bottom) / 2 - viewportCenter);
              measurements.push({ element, distance });
              if (rect.bottom >= 0 && rect.top <= window.innerHeight && distance < closestDistance) {
                closestElement = element;
                closestDistance = distance;
              }
            });

            measurements.forEach(({ element, distance }) => {
              rememberOpacity(element);
              let opacity = minimumOpacity;
              if (element === closestElement || distance <= focusRadius) {
                opacity = 1;
              } else if (distance < fadeRadius) {
                const progress = (distance - focusRadius) / (fadeRadius - focusRadius);
                opacity = 1 - progress * (1 - minimumOpacity);
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
