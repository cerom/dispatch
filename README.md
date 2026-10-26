# sohn손 — marketing site

Astro + TypeScript + Tailwind CSS v4 + shadcn/ui, with Lenis smooth scrolling and Motion animations.

## Getting started

Requires Node **24** (Astro 7 needs ≥ 22.23.4). An `.nvmrc` is included.

```sh
pnpm install
pnpm dev       # http://localhost:4321
pnpm build     # astro check + static build to dist/
pnpm preview
```

## Structure

```
src/
  layouts/Layout.astro        html shell, boots scroll + animation scripts
  components/
    Header.astro              floating pill nav (mobile menu included)
    sections/                 Hero, Manifesto, Science, Ritual, Shop, Footer
    ui/                       shadcn/ui components (pnpm dlx shadcn@latest add …)
  scripts/
    smooth-scroll.ts          Lenis smooth scroll
    reveal.ts                 Motion text/element reveals (data attributes below)
    pinned.ts                 pinned horizontal scroll sections
  styles/global.css           Tailwind theme + brand tokens mapped onto shadcn variables
                              (font: SF Pro via system stack, Inter fallback off Apple devices)
  assets/                     drop hero.(jpg|png|webp) here to replace the hero gradient
```

## Animation attributes

All animations respect `prefers-reduced-motion`, and content stays visible without JS.

| Attribute | Effect |
| --- | --- |
| `data-split="chars\|words"` | Masked, staggered slide-up when the element enters the viewport. Optional `data-delay`, `data-stagger` (seconds). |
| `data-reveal` | Fade-up on enter. Optional `data-delay`. |
| `data-reveal-group` | Staggered fade-up of direct children. |
| `data-scrub` | Words brighten one by one, tied to scroll position. |
| `data-parallax="0.2"` | Scroll-linked parallax within the nearest `data-parallax-root`. |
| `data-pin` + `data-pin-track` | Scroll hijack: section pins and vertical scroll moves the track sideways. Optional `data-pin-progress`, `data-pin-counter`. |
