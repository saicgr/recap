# Reppora Frontend Design — Glassmorphism Premium

Adapted from FitWiz's frontend-design command for Reppora's B2B coaching platform. Source of truth for the design system is `docs/conventions/glassmorphism.md`. This file gives Claude the design vocabulary to apply when generating UI code.

---

## 1. Reppora Visual Identity

- **Brand mark:** bold "R" wordmark
- **Primary accent:** Reppora indigo `#5B6BFF`
- **Secondary accent:** soft violet `#A78BFA`
- **Mood:** premium, professional, modern, trustworthy (B2B — distinct from FitWiz's brighter consumer palette)
- **Visual language:** Apple-style glassmorphism (frosted glass, soft shadows, light-catch borders)

---

## 2. Glass Hierarchy (apply consistently)

| Layer | Blur | Opacity | When to use |
|---|---|---|---|
| **Surface glass** | 8px | 15% | Primary content cards, dashboard widgets |
| **Overlay glass** | 12px | 20% | Modals, dropdowns, popovers, secondary cards |
| **Background glass** | 20px | 25% | Navigation bars, sidebars, app chrome |

Always: 1px white-alpha (40%) border on top edge ("light catch"), soft inner shadow, soft drop shadow `0 8px 32px rgba(31, 38, 135, 0.15)`.

**Web (Tailwind):** use the custom `glass-surface`, `glass-overlay`, `glass-background` utility classes from `web/styles/globals.css`.
**Flutter:** use pre-built `GlassCard`, `GlassModal`, `GlassNav` widgets from `lib/widgets/glass/`. Never hand-roll `BackdropFilter`.

---

## 3. Color Tokens (light/dark mode)

See `docs/conventions/glassmorphism.md §2` for the full palette. Use design tokens (`--accent-primary`, `--text-primary` etc.) — never raw hex in component code.

Light mode is the default for Reppora (B2B coaches use desktop in daylight). Dark mode is opt-in.

---

## 4. Typography — Inter variable

Sizes (web → mobile):
- Display: 64px → 48px / Hero: 48px → 36px / H1: 40px → 32px
- H2: 30px → 24px / H3: 24px → 20px
- Body: 16px / Body-sm: 14px / Caption: 12px

**Always meet WCAG AA contrast** (4.5:1 body, 3:1 large text) — use vibrancy layer if glass background hurts readability.

---

## 5. Spacing — 8px grid (no exceptions)

`4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96 / 128`

---

## 6. Component Patterns

### Buttons
- Primary: solid `--accent-primary`, white text, `rounded-xl`
- Secondary: `glass-surface` with accent border + accent text
- Tertiary: text-only, accent color
- Sizes: sm (32h) / md (40h) / lg (48h) / xl (56h, hero)

### Cards
Default = `glass-surface`. Padding 24px. Border radius `rounded-2xl` (16px).

### Inputs
Glass-overlay (12px blur), accent border on focus, label above (caption style).

### Modals + Bottom sheets
Glass-overlay; backdrop dims page (40% black). Animation: scale + fade in 200ms ease-out.

### Navigation
- Web sidebar: `glass-background`, full-height, sticky, `rounded-r-3xl`
- Web top bar: `glass-background`, sticky, `border-b` only
- Mobile bottom nav (Flutter): `GlassNav` widget, ≤5 tabs

---

## 7. Animation
- Easing: `cubic-bezier(0.4, 0, 0.2, 1)` standard; `cubic-bezier(0.34, 1.56, 0.64, 1)` for delight moments
- Durations: 150ms (micro), 250ms (component), 400ms (page), 600ms+ (hero only)
- Glass-specific: animate `backdrop-filter` from 0 → target blur over 200ms (frost-forming effect)
- Avoid: spinning loaders >1s — use skeleton + shimmer instead
- Respect `prefers-reduced-motion`

---

## 8. B2B-specific patterns (different from FitWiz consumer)

| Pattern | Why B2B-specific |
|---|---|
| **Data-dense tables** (client roster, take-rate ledger, MRR breakdown) | Coaches manage rosters; web layout assumes desktop |
| **Drag-and-drop builder** (program template, meal plan) | Desktop-only UX; mobile shows assigned-template list, no edit |
| **Side-by-side compare** (current vs reconstructed program in migration importer) | Coaches need diff view, not single-screen |
| **Inline editing** (cell-level edits in roster table) | Coaches edit dozens of fields/day; modals are too slow |
| **Keyboard-first shortcuts** (j/k navigation, ⌘K command palette) | Coaches are power users; mobile gestures don't translate |
| **MTD widgets** (live take-rate counter, adherence rates) | Coaches want at-a-glance financial + operational signals |
| **Per-client toggles** (AI features on/off per client) | Granular control; bulk-action UI for setting across N clients |

---

## 9. Iconography
- Lucide (web) + Lucide-Flutter (mobile)
- Stroke 1.5px default, 2px for emphasis
- Sizes: 16 / 20 / 24 / 32px
- Custom Reppora icons in `assets/icons/custom/` — match Lucide style

---

## 10. Component States

Every interactive element must have:
- **Default**
- **Hover** (web only): subtle lift + glow increase
- **Pressed**: scale down slightly, darker shade
- **Focused**: visible 2px accent ring (NEVER removed)
- **Disabled**: 40% opacity, no interaction
- **Loading**: skeleton matching content shape
- **Error**: accent-danger border + error message below

---

## 11. Performance budget
- Web: LCP <2.5s, CLS <0.1, FID <100ms (Lighthouse score >90)
- Mobile: 60fps during scroll, <100ms tap response
- Limit blur radius on low-end devices; static fallback if frame budget breaks
- GPU-accelerated properties only (transform, opacity); never animate layout

---

## 12. Pre-ship Checklist

Before shipping any UI:
- [ ] Works at all breakpoints (320 → 1440+)
- [ ] All component states implemented
- [ ] Meets WCAG AA contrast (verified with axe-core / Flutter accessibility tests)
- [ ] Touch targets ≥44×44px
- [ ] Respects `prefers-reduced-motion`
- [ ] Loading + error states present
- [ ] Glass effects have non-glass fallback for older devices
- [ ] Tested in light + dark mode
- [ ] Tested on real iOS device (not just simulator) for `client` and `coach` flavors
- [ ] No hardcoded colors / spacing — uses design tokens

---

## 13. Don't list

- ❌ Don't use Material elevation tokens — they fight glass aesthetics
- ❌ Don't use opaque backgrounds on glass surfaces
- ❌ Don't apply `backdrop-blur` to text (only containers)
- ❌ Don't nest more than 3 glass layers
- ❌ Don't deviate from 8px spacing grid
- ❌ Don't use accent colors as bulk fill (accent = emphasis, not background)
- ❌ Don't hardcode "FitWiz" anywhere in Reppora client app — use `TenantTheme.of(context).appName`
- ❌ Don't ship UI failing WCAG AA — CI gate
