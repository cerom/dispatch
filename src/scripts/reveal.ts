import { animate, inView, scroll, stagger } from "motion";

const EASE = [0.16, 1, 0.3, 1] as const;

type SplitMode = "chars" | "words";

/**
 * Wraps every word (and optionally every character) of `root` in masked
 * spans, preserving nested markup like `<span class="block">` line breaks.
 * Screen readers get the original text via aria-label.
 */
function splitText(root: HTMLElement, mode: SplitMode): HTMLElement[] {
  const units: HTMLElement[] = [];
  if (!root.hasAttribute("aria-label")) {
    root.setAttribute(
      "aria-label",
      root.textContent?.replace(/\s+/g, " ").trim() ?? "",
    );
  }

  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
  const textNodes: Text[] = [];
  while (walker.nextNode()) textNodes.push(walker.currentNode as Text);

  for (const node of textNodes) {
    const text = node.textContent ?? "";
    if (!text.trim()) continue;

    const frag = document.createDocumentFragment();
    for (const part of text.split(/(\s+)/)) {
      if (!part) continue;
      if (/^\s+$/.test(part)) {
        frag.append(document.createTextNode(" "));
        continue;
      }
      const mask = document.createElement("span");
      mask.className = "split-mask";
      mask.setAttribute("aria-hidden", "true");

      const pieces = mode === "chars" ? Array.from(part) : [part];
      for (const piece of pieces) {
        const unit = document.createElement("span");
        unit.className = "split-unit";
        unit.textContent = piece;
        mask.append(unit);
        units.push(unit);
      }
      frag.append(mask);
    }
    node.replaceWith(frag);
  }
  return units;
}

/** `data-split="chars|words"` — masked, staggered slide-up when in view. */
function initSplitReveals(reduced: boolean) {
  document.querySelectorAll<HTMLElement>("[data-split]").forEach((el) => {
    const mode = (el.dataset.split as SplitMode) || "words";
    const units = splitText(el, mode);
    if (reduced) return;

    const delay = Number(el.dataset.delay ?? 0);
    const each = Number(el.dataset.stagger ?? (mode === "chars" ? 0.03 : 0.06));

    inView(
      el,
      () => {
        animate(
          units,
          { y: ["110%", "0%"] },
          {
            duration: 1.1,
            ease: EASE,
            delay: stagger(each, { startDelay: delay }),
          },
        );
      },
      { amount: 0.3 },
    );
  });
}

/** `data-reveal` — single element fade-up. `data-reveal-group` — staggered children. */
function initFadeReveals(reduced: boolean) {
  if (reduced) return;

  document.querySelectorAll<HTMLElement>("[data-reveal]").forEach((el) => {
    const delay = Number(el.dataset.delay ?? 0);
    inView(
      el,
      () => {
        animate(
          el,
          { opacity: [0, 1], y: ["2rem", "0rem"] },
          { duration: 1, ease: EASE, delay },
        );
      },
      { amount: 0.2 },
    );
  });

  document
    .querySelectorAll<HTMLElement>("[data-reveal-group]")
    .forEach((group) => {
      const children = Array.from(group.children) as HTMLElement[];
      inView(
        group,
        () => {
          animate(
            children,
            { opacity: [0, 1], y: ["2rem", "0rem"] },
            { duration: 1, ease: EASE, delay: stagger(0.12) },
          );
        },
        { amount: 0.15 },
      );
    });
}

/**
 * `data-scrub` — words brighten one after another as the block scrolls
 * through the viewport (scroll-linked, not time-based).
 */
function initScrubText(reduced: boolean) {
  document.querySelectorAll<HTMLElement>("[data-scrub]").forEach((el) => {
    const words = splitText(el, "words");
    // Scrub text shouldn't slide; only its opacity is driven.
    words.forEach((w) => (w.style.transform = "none"));
    if (reduced) return;

    words.forEach((w) => (w.style.opacity = "0.16"));
    scroll(
      (progress: number) => {
        const lit = progress * words.length;
        words.forEach((w, i) => {
          w.style.opacity = String(
            0.16 + 0.84 * Math.min(1, Math.max(0, lit - i)),
          );
        });
      },
      { target: el, offset: ["start 0.85", "end 0.45"] },
    );
  });
}

/** `data-parallax="<factor>"` — translates relative to its own viewport progress. */
function initParallax(reduced: boolean) {
  if (reduced) return;
  document.querySelectorAll<HTMLElement>("[data-parallax]").forEach((el) => {
    const factor = Number(el.dataset.parallax || 0.2);
    const target =
      (el.closest("[data-parallax-root]") as HTMLElement | null) ?? el;
    scroll(animate(el, { y: ["0%", `${factor * 100}%`] }, { ease: "linear" }), {
      target,
      offset: ["start start", "end start"],
    });
  });
}

export function initReveals() {
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  initSplitReveals(reduced);
  initFadeReveals(reduced);
  initScrubText(reduced);
  initParallax(reduced);
}
