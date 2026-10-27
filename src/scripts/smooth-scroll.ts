import Lenis from "lenis";

/**
 * Hijacks native wheel/touch scrolling and replaces it with an eased,
 * inertia-based scroll. Native scroll position is still updated, so
 * Motion's `scroll()` / `inView()` and `position: sticky` keep working.
 */
export function initSmoothScroll() {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const lenis = new Lenis({
    autoRaf: true,
    lerp: 0.085,
    wheelMultiplier: 0.9,
    anchors: { offset: -24 },
  });

  return lenis;
}
