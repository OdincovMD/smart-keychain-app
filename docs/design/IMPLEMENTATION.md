# Chrome Kiss Flutter Implementation

> Статус: design-token foundation implemented. Этот слой не является
> редизайном существующих экранов.

## Appearance boundary

`AppAppearance` хранит выбор пользователя: `obsidian`, `pearl` или `system`.
Domain не читает platform brightness. На Flutter boundary `MaterialApp`
сопоставляет выбор с `ThemeMode`; поэтому `system` разрешается операционной
системой в одну из двух curated themes.

```text
AppAppearance (domain + persistence)
  ↓ AppearanceController
ThemeMode (Flutter boundary)
  ↓ platform brightness when mode == system
Obsidian ThemeData | Pearl ThemeData
```

## Color token mapping

Все product components получают цвета через `ThemeExtension`, а не через
appearance-specific hex или проверку brightness:

```dart
final colors = context.chromeKiss;
final canvas = colors.canvas;
final lens = colors.lens;
```

| Design token | Flutter API |
|---|---|
| `color.canvas` | `context.chromeKiss.canvas` |
| `color.lens` | `context.chromeKiss.lens` |
| `color.text.primary` | `context.chromeKiss.textPrimary` |
| `color.text.secondary` | `context.chromeKiss.textSecondary` |
| `color.text.onAccent` | `context.chromeKiss.onAccent` |
| `color.accent.primary` | `context.chromeKiss.accentPrimary` |
| `color.accent.optical` | `context.chromeKiss.accentOptical` |
| `color.material.chrome` | `context.chromeKiss.materialChrome` |
| `color.material.champagne` | `context.chromeKiss.materialChampagne` |
| `color.surface.secondary` | `context.chromeKiss.surfaceSecondary` |
| `color.divider` | `context.chromeKiss.divider` |
| `color.success` | `context.chromeKiss.success` |
| `color.warning` | `context.chromeKiss.warning` |
| `color.danger` | `context.chromeKiss.danger` |

`ChromeKissColors.forAppearance(...)` — единственное место, где semantic roles
получают exact values из `DESIGN.md`. Product components не должны содержать
прямые theme hex, `AppAppearance` branches или собственные dark/light palettes.

Glossy lens остаётся `#020205` в обеих appearances. На Pearl Hot Orchid и Icy
Lilac не применяются как мелкий текст; label поверх primary accent использует
`color.text.onAccent`.

## Typography mapping

Chrome Kiss использует утверждённую пару локальных font assets из официального
Google Fonts repository. Оба семейства распространяются по SIL Open Font
License; соответствующие `*-OFL.txt` хранятся рядом с TTF в `assets/fonts/`.

| Design role | Flutter API | Current family |
|---|---|---|
| `text.display` | `context.chromeKissText.display` | Unbounded |
| `text.title` | `context.chromeKissText.title` | Unbounded |
| `text.body` | `context.chromeKissText.body` | Manrope |
| `text.label` | `context.chromeKissText.label` | Manrope |
| `text.status` | `context.chromeKissText.status` | Manrope |

Unbounded применяется только к коротким hero/section titles. Material settings,
body copy, buttons, status и captions остаются в Manrope. Legacy font assets не
удалены, чтобы не менять вне текущего milestone старые visual surfaces.

## Motion mapping

Tokens choose one representative duration inside each range documented in
`MOTION.md`. They establish vocabulary only; this milestone does not add new
complex animation.

| Design token | Flutter API | Current draft |
|---|---|---:|
| `motion.micro` | `context.chromeKissMotion.micro` | `100 ms`, `easeOutCubic` |
| `motion.interaction` | `context.chromeKissMotion.interaction` | `180 ms`, `easeOutCubic` |
| `motion.transition` | `context.chromeKissMotion.transition` | `300 ms`, `easeInOutCubic` |
| `motion.delight` | `context.chromeKissMotion.delight` | `600 ms`, `easeOutBack` |

## Persistence

`app_settings.appearance` stores the stable enum string. Schema version 3 adds
the column with default `system` and a `CHECK` constraint. Startup restoration
loads it before `runApp`, so the first frame uses the restored appearance.
`AppearanceController` persists successfully before publishing the new state.

## Current migration boundary

Safe product-level colors on existing screens now use semantic roles without
changing their layout. Remaining direct colors are intentionally limited to:

- the legacy coral virtual hardware illustration;
- procedural character content colors inside the black display;
- static scene/image rendering fallbacks;
- transparent compositing values and the token definitions themselves.

Those are content/material recipes rather than appearance canvas or text roles.
They should move to dedicated hardware/character/renderer palettes during their
respective visual milestones, not be silently mapped to app-theme colors.
