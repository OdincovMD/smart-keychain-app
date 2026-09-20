# Chrome Kiss Flutter Implementation

> Статус: design-token foundation implemented; основные companion, wardrobe,
> import/editor и look lifecycle surfaces переведены на Chrome Kiss.

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

## Production Settings and Appearance

Пользовательский entry следует локальной navigation-модели продукта и не
расширяет app-wide router:

```text
Companion Home settings trigger
  ↓ local Navigator route
Production Settings
  ↓ ChromeKiss material sheet
Appearance: Obsidian | Pearl | System
```

Back из Appearance возвращает в тот же Settings route, а Back из Settings — в
тот же Home и живую device session. Settings читает существующий
`DeviceSnapshot`, переиспользует `BrightnessControl` и вызывает существующий
`DeviceController` для brightness/disconnect. Неизвестные firmware, storage,
serial и hardware values не моделируются.

`AppearanceController` остаётся единственным presentation owner. Он
последовательно записывает быстрые selections, публикует theme только после
успешного `AppSettingsRepository.saveAppearance` и сохраняет последний запрос в
очереди. Ошибка не меняет confirmed selection и показывается inline рядом с
вариантами с доступным retry; смена theme не закрывает material sheet.

Production Settings не содержит simulator latency, fake battery, forced states
или diagnostics. Текущий simulator entry остаётся отдельным debug-only sheet на
Home и физически отсутствует в release UX.

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
| `text.display` | `context.chromeKissText.display` | Cormorant Garamond |
| `text.title` | `context.chromeKissText.title` | Cormorant Garamond |
| `text.body` | `context.chromeKissText.body` | Manrope |
| `text.label` | `context.chromeKissText.label` | Manrope |
| `text.status` | `context.chromeKissText.status` | Manrope |
| Script accent | локальный акцент в hero composition | Great Vibes |

Cormorant Garamond применяется только к коротким hero/section titles. Material
settings, body copy, buttons, status и captions остаются в Manrope. Great Vibes
допустим только как редкая эмоциональная подпись и не используется в controls.

## Motion mapping

Tokens choose one representative duration inside each range documented in
`MOTION.md`. Look application использует `transition` для изменения размера
material sheet и собственный indeterminate ring; при `disableAnimations` смена
состояния остаётся мгновенной, а кольцо — статичным и понятным без движения.

| Design token | Flutter API | Current draft |
|---|---|---:|
| `motion.micro` | `context.chromeKissMotion.micro` | `100 ms`, `easeOutCubic` |
| `motion.interaction` | `context.chromeKissMotion.interaction` | `180 ms`, `easeOutCubic` |
| `motion.transition` | `context.chromeKissMotion.transition` | `300 ms`, `easeInOutCubic` |
| `motion.delight` | `context.chromeKissMotion.delight` | `600 ms`, `easeOutBack` |

## Look application lifecycle

Детали образа и применение используют feature-local presentation state:

```text
ready → applying ─┬→ applied
                  └→ failed → retry → applying
```

`applied` публикуется только после успешного завершения команды
`DeviceController.setScene` и появления того же `scene.id` в
`DeviceSnapshot.activeSceneId`. Поэтому UI не показывает оптимистический успех
и не рисует фиктивные проценты. Повторное нажатие во время команды блокируется;
закрытие sheet уничтожает auto-dispose state. Ошибка и retry остаются внутри
той же material surface без параллельного SnackBar.

Applying, Applied и Error используют одинаковую геометрию, реальный preview и
имя сцены. Success/error различаются не только цветом, но также формой кольца,
glyph и текстом. Delete confirmation показывает реальную сцену и сохраняет
ошибку inline, позволяя повторить удаление.

## Production connection recovery

Companion Home владеет feature-local `ConnectionRecoveryController`,
параметризованным стабильным `deviceId`. Он различает намеренное отключение и
неожиданную потерю связи, дедуплицирует повторные `disconnected` events и
запускает не больше одной автоматической попытки на один эпизод потери.

```text
connected → disconnected → reconnecting ─┬→ ready → connected
                                          └→ failed → retry
```

Завершение `connect` Future не считается успехом: Home возвращается только после
реального `DeviceConnectionStatus.ready`. Ошибка остаётся inline без SnackBar и
предлагает Retry или возврат к Discovery. Намеренный disconnect сначала отмечает
intent, затем выполняет существующую `DeviceController.disconnect` команду и не
запускает auto-reconnect. Если другая device-команда уже активна, disconnect
ставится за ней в очередь и не теряется.

Disconnected/Reconnecting используют общий `ChromeKissFidelityFrame`,
`CompanionStage`, semantic appearance tokens и `JewelButton`. Reconnecting rim
indeterminate и не показывает фиктивный процент; в reduced-motion он остаётся
статичным, сохраняя текстовый и формовый state signal.

## Production Home async states

Home выводит presentation state из существующих Riverpod `AsyncValue` и не
создаёт вторую domain- или connection-state machine. Приоритет фиксирован:

```text
intentional disconnect navigation
  ↓
connection recovery (когда доступны last-known snapshot + active scene)
  ↓
valid Home
  ↓
scene library / active scene loading or failure
  ↓
initial snapshot loading or unavailable
```

Initial snapshot и content loading используют общий Chrome Kiss loading stage:
приглушённую lens, спокойные Kiss Cut eyes и optical rim без фиктивного
прогресса. При reduced motion rim остаётся статичным. Ошибки сохраняют ту же
композицию, различаются glyph, заголовком и действием, а не только цветом.

После появления пригодных данных refresh сохраняет last-known-good Home и
добавляет компактный optical status без изменения основной геометрии. Retry
инвалидирует только конкретный упавший provider: snapshot, scene library или
active scene. Повторный Retry во время refresh блокируется. Snapshot failure не
считается потерей connection и не вызывает `ConnectionRecoveryController`;
возврат к Discovery остаётся отдельным явным действием пользователя.

Весь пользовательский и accessibility copy Home async и Connection Recovery
принадлежит Flutter localization catalog. Production widgets не содержат
захардкоженных русских строк для этих состояний.

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
