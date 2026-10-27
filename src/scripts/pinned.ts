import { scroll } from "motion";

/**
 * Scroll hijack: `[data-pin]` is a tall section whose sticky child stays in
 * the viewport while vertical scroll drives `[data-pin-track]` sideways.
 * The section's height is derived from the track width so one pixel of
 * vertical scroll maps to one pixel of horizontal travel.
 */
export function initPinnedSections() {
  document.querySelectorAll<HTMLElement>("[data-pin]").forEach((section) => {
    const track = section.querySelector<HTMLElement>("[data-pin-track]");
    const bar = section.querySelector<HTMLElement>("[data-pin-progress]");
    const counter = section.querySelector<HTMLElement>("[data-pin-counter]");
    if (!track) return;

    const panels = Array.from(track.children) as HTMLElement[];
    let distance = 0;

    const measure = () => {
      distance = Math.max(0, track.scrollWidth - window.innerWidth);
      section.style.height = `${distance + window.innerHeight}px`;
    };
    measure();
    new ResizeObserver(measure).observe(track);
    window.addEventListener("resize", measure);

    scroll(
      (progress: number) => {
        track.style.transform = `translate3d(${-progress * distance}px, 0, 0)`;
        if (bar) bar.style.transform = `scaleX(${progress})`;
        if (counter) {
          const index = Math.min(
            panels.length,
            Math.floor(progress * panels.length) + 1,
          );
          counter.textContent = String(index).padStart(2, "0");
        }
      },
      { target: section, offset: ["start start", "end end"] },
    );
  });
}
