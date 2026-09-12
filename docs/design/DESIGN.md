# Chrome Kiss Design Foundation

> Статус: direction approved, Companion Home fidelity pass implemented
>
> Primary direction: Chrome Kiss
>
> Secondary influence: Pearl Orbit
>
> Rare delight influence: Popstar Pet Club

Этот документ фиксирует продуктовый visual language Smart Keychain. Он не
описывает Flutter API, структуру виджетов или конкретную реализацию экранов.

## Visual Thesis

**Chrome Kiss — живой digital companion внутри глянцевой чёрной линзы,
оформленный как уверенный fashion-tech аксессуар с точными chrome-деталями и
редкими candy-акцентами.**

Интерфейс должен ощущаться как digital jewelry, которое умеет смотреть,
реагировать и менять образ. Glam возникает из материала, света, типографики и
поведения, а не из случайного розового градиента или декоративного шума.

Chrome Kiss поддерживает две curated appearance variants:

- **Obsidian** — исходная тёмная подача с глубоким canvas;
- **Pearl** — светлая подача на мягкой pearl-поверхности.

Это две экспозиции одной identity, а не две дизайн-системы. Они используют одну
иерархию, component language, typography, spacing, motion и character anatomy.
Glossy black companion lens, Hot Orchid и Icy Lilac сохраняются в обеих.

## Brand Temperament

Chrome Kiss:

- confident;
- flirty;
- glamorous;
- playful;
- expressive;
- collectible;
- premium;
- slightly mischievous.

Chrome Kiss **не** является:

- childish или preschool;
- corporate или sterile minimal;
- cyberpunk, gamer UI или sci-fi control panel;
- kawaii overload;
- generic pink app;
- Material dashboard;
- набором одинаковых карточек с декоративным glow.

Feminine-направление выражается через уверенность, материал, пластику и
fashion-ритуалы. Оно не должно строиться на стереотипном использовании сердец,
блёсток или розового цвета.

## Product Hierarchy

```text
Character
  ↓
Current look / mood
  ↓
Interaction
  ↓
Collection / wardrobe
  ↓
Device state
```

Батарея, соединение и яркость важны, но являются secondary information. Они не
должны конкурировать с персонажем за самую крупную область, самый яркий цвет или
первое действие на экране.

## Color Roles

Палитра компактна и семантична. Компонент запрашивает роль — canvas, основной
текст, secondary surface или подтверждённый success — и не выбирает значение по
названию appearance. Конкретное значение роли приходит из Obsidian или Pearl.

### Obsidian

Тёмная исходная подача Chrome Kiss. Глубокий почти чёрный canvas растворяет
границы glossy lens, а светлые chrome-линии и candy accents проявляют материал.
Secondary surfaces остаются близкими к canvas и не превращаются в серую card
wall.

### Pearl

Светлая подача той же Chrome Kiss identity. Canvas — мягкий rose-pearl
`#F8F2F6`, не pure `#FFFFFF`. Он сохраняет лёгкое тепло рядом с холодным chrome,
но достаточно нейтрален для Hot Orchid и пользовательских looks. Glossy black
lens остаётся неизменной и создаёт главный optical contrast.

Pearl не инвертирует все цвета механически. Text и state roles становятся
темнее; chrome получает более глубокий средний тон, различимый на pearl canvas;
surface и divider отделяются изменением lightness, а не тенями вокруг каждой
секции.

### Shared identity colors

| Role | Value | Purpose | Guardrail |
|---|---|---|---|
| Lens | Near black `#020205` | Экран персонажа и оптическая глубина | Не осветлять в Pearl и не превращать в обычную card |
| Primary glam accent | Hot Orchid `#FF4FB8` | Primary action, active look, редкий эмоциональный акцент | На Pearl не использовать как мелкий текст или единственную границу control |
| Secondary optical accent | Icy Lilac `#C9BEFF` | Отражение, selection detail, оптическая связь | На Pearl использовать на lens или вместе с тёмной формой/marker |

Коралловый может появляться в отдельных look или collectible-моментах, но больше
не является основным цветом бренда или обязательным цветом корпуса.

Цвет не должен быть единственным носителем active, success, warning или error
state. Нужны форма, текст, иконка или изменение композиции.

## Material Language

### Glossy black lens

Главная материальная поверхность. Почти чёрная, глубокая, с локальным
specular highlight по краю. Это не обычная чёрная карточка и не стеклянная
панель с текстом поверх неё.

### Chrome

Тонкая структурная кромка, соединитель или jewel-detail. Chrome строится из
последовательности тёмного отражения, светлой линии и одного холодного блика.
Rainbow chrome не является базовым материалом. В Obsidian базовый тон chrome
светлый; в Pearl — более глубокий neutral-mauve, чтобы материал не исчезал на
светлом canvas. Это один material recipe с разной экспозицией, а не разные
металлы.

### Lacquer

Плотный насыщенный цвет с контролируемой отражающей полосой. Используется для
primary glam accent и редких крупных интерактивных деталей, а не как фон каждого
контейнера.

### Tinted jelly

Полупрозрачный цветной материал для небольших tabs, selection markers или
collectible-деталей. Под ним должна читаться конкретная поверхность. Произвольная
прозрачность без материальной логики запрещена.

### Pearl / champagne

Вторичная нота Pearl Orbit: мягкие тёплые поверхности, спокойные состояния и
премиальные детали. Используется локально, чтобы Chrome Kiss не становился
холодным или gamer-like. Название appearance Pearl не означает champagne wash
поверх всего интерфейса: основной canvas остаётся спокойным off-white, а
champagne — редкой материальной нотой.

### Specular highlights

У каждого блика должен быть предполагаемый источник света, направление и
материал. Highlights одной сцены согласованы между собой. Random radial glow,
светящиеся пятна без объекта и blur ради «премиальности» не используются.

## Shape Language

- **Circular lens** — hero geometry и портал к персонажу.
- **Stretched fashion tab** — вытянутая форма для primary actions и выбора
  разделов; она отличается от обычной pill пропорциями и материальной кромкой.
- **Jewel control** — компактный тактильный control с выраженным центром и
  оптическим edge.
- **Thin optical line** — связь между объектами, selection или граница
  материала без создания новой карточки.
- **Star pinch / sparkle** — редкий акцент успеха или collectible-момента, не
  постоянный паттерн.
- **Controlled asymmetry** — смещённый блик, один выступ или различный вес
  соседних зон; структура и touch targets остаются предсказуемыми.

Обычный rounded rectangle допустим только когда он объясняет containment,
interaction или material sheet. Нельзя превращать каждый текст, статус и блок в
отдельную карточку или pill.

## Typography Roles

Окончательные font files на этом этапе не выбираются. Любой кандидат обязан
качественно поддерживать кириллицу, цифры и системные accessibility-настройки.

| Role | Character | Use | Avoid |
|---|---|---|---|
| Display | Fashion-oriented extended или condensed grotesk; уверенный, немного острый | Короткие hero-заголовки и имя companion | Детские округлые буквы, длинные абзацы, all caps повсюду |
| Title | Выразительный, но спокойнее Display | Названия зон, look и material sheet | Одинаковый вес с body и status |
| Body | Нейтральный современный grotesk с высокой читаемостью | Инструкции, сообщения, описание действия | Fashion-эффекты, узкий шрифт, низкий контраст |
| Label | Компактный и уверенный | Buttons, tabs, actions | Избыточный letter spacing и технический uppercase |
| Micro / Status | Табулярные цифры, ясные формы, повышенная точность | Батарея, связь, secondary metadata | Доминирование над character или primary action |

Display создаёт fashion posture, но Body и Label сохраняют скорость чтения и
понятность. Типографика не должна имитировать логотипы конкретных брендов.

## Spacing and Composition

Базовый ритм строится на ограниченном наборе расстояний, но композиция не
должна выглядеть как `card → gap → card → gap → card`.

Основные зоны:

1. **Companion Stage** — персонаж, current look и ощущение присутствия.
2. **Quick Interaction** — одно главное действие и контекстная реакция.
3. **Wardrobe** — визуальный ряд доступных look.
4. **Secondary Controls** — яркость, связь, батарея и настройки по запросу.

Character Stage получает больше свободного пространства, чем utility-зоны.
Secondary controls могут быть плотнее. Асимметрия допустима в визуальном весе,
но не должна нарушать reading order или достижимость действий.

## Component Language

Это продуктовые primitives, а не API будущих Flutter widgets.

| Primitive | Purpose | Visual principle | Use when | Do not use when |
|---|---|---|---|---|
| `CompanionStage` | Дать персонажу главную сцену и показать текущий look/mood | Почти full-face lens, минимум chrome, свободное поле вокруг | Home, важная preview перед применением | Для маленькой карточки, status summary или технической схемы |
| `LookTile` | Представить один wearable look и его состояние | Визуальный preview первичен; название и active marker вторичны | Wardrobe, recent looks, выбор образа | Для настроек, файлов или несвязанных действий |
| `WardrobeRail` | Объединить built-in и user looks в одну коллекцию | Направленный визуальный ряд с ясной выбранной позицией | Быстрый browse и переход к полной коллекции | Для длинной формы или диагностического списка |
| `JewelButton` | Главный либо редкий premium action | Тактильный центр, lacquer/chrome edge, ясный pressed state | Change Look, Pair, подтверждённый primary action | Для каждой вторичной команды или длинного набора кнопок |
| `StatusGlyph` | Показать связь, батарею или небольшой state без отдельной зоны | Иконка + короткое значение; цвет не единственный сигнал | Периферия Companion Stage, compact header | Как крупная hero-card или декоративный badge |
| `LensSurface` | Содержать экран, media preview или оптический фокус | Чёрная глубина, физически объяснимый edge и highlight | Character, круглое crop preview, важный look | Для текста, настроек или произвольной карточки |
| `MaterialSheet` | Временно раскрыть secondary actions и settings | Одна материальная плоскость, ясная связь с trigger | Quick settings, item details, destructive confirmation | Как постоянный контейнер вокруг каждой секции |

## Semantic Appearance Tokens

Tokens описывают намерение и не привязаны к `ThemeData`, brightness enum или
конкретному renderer. Obsidian и Pearl обязаны предоставлять один и тот же набор
ролей.

| Token | Obsidian | Pearl | Meaning |
|---|---:|---:|---|
| `color.canvas` | `#0B0A0F` | `#F8F2F6` | Основной app canvas |
| `color.lens` | `#020205` | `#020205` | Неизменная glossy companion lens |
| `color.text.primary` | `#F8F4FA` | `#241A22` | Заголовки и основной текст |
| `color.text.secondary` | `#AAA5B3` | `#655A63` | Подписи и secondary information |
| `color.text.onAccent` | `#0B0A0F` | `#241A22` | Текст и glyph поверх Hot Orchid |
| `color.accent.primary` | `#FF4FB8` | `#FF4FB8` | Главный glam action / active look |
| `color.accent.optical` | `#C9BEFF` | `#C9BEFF` | Холодная optical связь и highlight |
| `color.material.chrome` | `#D9D8E2` | `#8F8893` | Базовый chrome edge/material detail |
| `color.material.champagne` | `#E7C98B` | `#9A6F36` | Тёплая secondary material нота |
| `color.surface.secondary` | `#17161C` | `#EEE6EC` | MaterialSheet, grouped utility и временная secondary surface |
| `color.divider` | `#34313A` | `#CFC5CD` | Тихое структурное разделение без card border |
| `color.success` | `#67DFB2` | `#187A65` | Подтверждённый успех и ready state |
| `color.warning` | `#F2C66D` | `#805E00` | Требующее внимания, но не опасное состояние |
| `color.danger` | `#FF647C` | `#C23455` | Destructive action и критическая ошибка |

### Shared non-color foundation tokens

Эти roles одинаковы в обеих appearances.

| Token | Draft value | Meaning |
|---|---:|---|
| `radius.lens` | `full` | Круглая hero geometry |
| `radius.control` | `18` | Jewel controls и stretched tabs |
| `radius.sheet` | `28` | Крупная временная material surface |
| `space.micro` | `4` | Внутренняя оптическая коррекция |
| `space.tight` | `8` | Связанные label/icon элементы |
| `space.control` | `12` | Внутренний ритм controls |
| `space.section` | `20` | Связанные части композиционной зоны |
| `space.zone` | `32` | Переход между зонами |
| `motion.micro` | `80–120 ms` | Press и micro-feedback |
| `motion.interaction` | `140–220 ms` | Selection и обычная смена state |
| `motion.transition` | `240–360 ms` | Sheet и spatial continuity |
| `motion.delight` | `450–800 ms` | Редкий branded moment |

Числа являются draft foundation. Перед переносом в production tokens они должны
быть проверены на реальных экранах, text scale и размерах устройств.

### Component color contract

**Никаких прямых hardcoded theme colors внутри product components.**

- `CompanionStage`, `LookTile`, `WardrobeRail`, `JewelButton`, `StatusGlyph`,
  `LensSurface` и `MaterialSheet` получают только semantic color roles.
- Product component не проверяет `if Obsidian/Pearl` и не выбирает `black`,
  `white`, `pink` или hex напрямую.
- Appearance resolver сопоставляет один набор semantic roles значениям из
  таблицы выше; layout, typography и state logic остаются общими.
- Цвета scene artwork и procedural character look считаются content palette, но
  их framing, labels, selection и accessibility feedback всё равно используют
  semantic theme tokens.
- Новый цвет сначала получает повторяемую semantic role. Разовый декоративный
  эффект остаётся частью material/character recipe и не становится скрытым
  component-level theme override.

### Companion Home Figma fidelity mapping

Глобальный runtime owner остаётся `ChromeKissColors`. Для Obsidian Home узел
Figma `2:2` задаёт более точный component recipe, изолированный в
`CompanionHomeTokens`: это не смена палитры остальных экранов и не вторая тема.

| Home role | Figma value | Runtime owner |
|---|---:|---|
| Primary text / specular | `#F8F3FF` | `CompanionHomeTokens.textPrimary` |
| Secondary text | `#C7B6D9` | `CompanionHomeTokens.textSecondary` |
| Glass surface | `#171222` | `CompanionHomeTokens.glass` |
| Subtle chrome border | `rgba(217, 216, 226, 0.24)` | `CompanionHomeTokens.borderSubtle` |
| Lacquer highlight | `#FF8CD1` | `CompanionHomeTokens.lacquerHighlight` |
| Lacquer body | `#FF4FB8` | `CompanionHomeTokens.lacquerPrimary` |
| Lacquer mid-depth | `#B80A6E` | `CompanionHomeTokens.lacquerMid` |
| Lacquer depth | `#470533` | `CompanionHomeTokens.lacquerDepth` |

Pearl Home продолжает брать semantic roles из `ChromeKissColors.pearl`; единая
иерархия и geometry сохраняются, а Obsidian-only fidelity recipe не протекает в
discovery, wardrobe или editor.

### Surface and divider roles

- `color.canvas` несёт большинство negative space.
- `color.surface.secondary` используется только когда нужны containment,
  temporary elevation или ясное grouping; он не создаёт card для каждой секции.
- `color.divider` — hairline/optical separator. Он не заменяет spacing и не
  обязан быть заметен как рамка.
- На Pearl elevation выражается сменой pearl tone и controlled chrome edge, а не
  серыми shadows вокруг каждого блока.

### Contrast evidence

Проверка solid colors локальным WCAG calculator:

| Pair | Obsidian | Pearl | Result |
|---|---:|---:|---|
| Primary text / canvas | `18.14:1` | `15.27:1` | AAA normal text |
| Secondary text / canvas | `8.21:1` | `5.95:1` | AA normal text |
| Hot Orchid / canvas | `6.63:1` | `2.69:1` | Pearl: не годится как мелкий текст или единственная control boundary |
| On-accent text / Hot Orchid | `6.63:1` | `5.67:1` | AA normal text |
| Icy Lilac / canvas | `11.55:1` | `1.55:1` | Pearl: только decorative detail или paired state signal |
| Chrome / canvas | `13.97:1` | `3.11:1` | Pearl chrome может обозначать essential component edge |
| Success / canvas | `12.00:1` | `4.74:1` | AA normal text |
| Warning / canvas | `12.28:1` | `5.41:1` | AA normal text |
| Danger / canvas | `6.92:1` | `4.86:1` | AA normal text |
| Icy Lilac / lens | `12.13:1` | `12.13:1` | Высокий optical contrast внутри общей black lens |

Hot Orchid сохраняется без затемнения в Pearl ради единой identity. Поэтому
`JewelButton` использует тёмный `color.text.onAccent`, а его essential boundary
дублируется различимым chrome/dark edge и формой. Orchid-only microtext,
Orchid-only focus ring и Orchid-only selected outline на Pearl запрещены.
Аналогично Icy Lilac на светлом canvas является декоративным optical accent, а
не единственным носителем selection state.

## Accessibility

- Normal text стремится к контрасту не ниже WCAG AA `4.5:1`, крупный текст и
  значимые графические элементы — не ниже `3:1`.
- Частые touch targets должны стремиться к размеру не меньше `44×44` logical
  pixels; никакое jewel-оформление не уменьшает активную область.
- Active, success, warning и danger не кодируются одним цветом.
- Semantics описывают действие и результат, а не материал или декоративный
  эффект.
- Увеличение текста не скрывает primary action и не ломает reading order.
- Reduced motion сохраняет состояние, feedback и навигационную ориентацию.
- Specular highlight не снижает читаемость текста и не проходит поверх него.
- Никакое essential action не зависит от hover, sparkle или сложного gesture.

## Do Not Use

- wall of cards;
- every label as pill;
- arbitrary glassmorphism;
- generic gradient buttons;
- random glow и radial gradients без физического источника;
- oversized technical status;
- Material defaults как финальный visual design;
- pink everywhere;
- decorative hearts everywhere;
- excessive sparkles;
- chrome rainbow на каждой поверхности;
- blur как замена композиции;
- typography, копирующая узнаваемый fashion-бренд;
- технические `scene ID`, `engine`, `latency`, `asset` и `command` в основном
  consumer UI.

## Reference Screen A — Pairing / Discovery

**Primary emotion:** anticipation — встреча с новым аксессуаром, а не настройка
оборудования.

**Primary object:** почти full-face изображение линзы брелока с коротким живым
взглядом; физическая рамка минимальна.

**Primary action:** `Подключить` / `Познакомиться` в зависимости от финального
product copy review.

**Secondary information:** найденное устройство, состояние поиска, короткая
помощь при неудаче. Demo mode доступен только как вторичный developer context.

**Composition:** сверху короткий уверенный title, в центре крупный object reveal,
внизу один JewelButton. При нескольких устройствах object reveal уступает место
простому выбору, но companion preview остаётся визуальным якорем.

**What must not appear:** большая IoT-карточка, battery hero, технический device
ID, постоянный badge «демо-режим», список возможностей или dashboard metrics.

Discovery — transient pairing ritual. После первого успешного pairing обычный
запуск ведёт к Companion Home, если состояние устройства позволяет это сделать.

## Reference Screen B — Companion Home

**Primary emotion:** presence — «он здесь, живой и мой».

**Primary object:** `CompanionStage` с максимально крупной линзой и текущим
характером.

**Primary action:** `Сменить образ`.

**Secondary information:** current look/mood, короткий Wardrobe preview, compact
StatusGlyph для батареи/соединения; яркость и остальные настройки раскрываются
по запросу.

**Composition:** Character Stage занимает верхнюю и наиболее выразительную
часть. Под ним находится короткая строка присутствия/mood и один главный action.
WardrobeRail продолжает текущий образ. Secondary Controls не образуют отдельный
dashboard и не конкурируют с линзой.

**What must not appear:** brightness как hero-card, крупные connection/battery
панели, постоянный debug control, тяжёлый коралловый bezel, длинная техническая
инструкция или несколько равнозначных CTA.

## Reference Screen C — Wardrobe / My Content

**Primary emotion:** self-expression — выбор того, как companion выглядит
сейчас.

**Primary object:** единая коллекция built-in и user-created `LookTile`.

**Primary action:** применить выбранный look; добавление собственного изображения
остаётся заметным, но не конкурирует с текущим выбором.

**Secondary information:** source/type только когда это помогает действию;
редактирование crop и удаление доступны в контексте user-created look.

**Composition:** visual-first collection с ясным current marker. Preview крупнее
metadata. Browse, inspect/edit и apply не смешиваются в одну строку мелких
иконок. Empty state показывает первый пустой look-slot и явное действие создания.

**What must not appear:** filesystem vocabulary, asset IDs, одинаковые file
cards, technical tags, icon-only destructive action без названия/подтверждения.

Пользователь думает в терминах `look`, `style`, `wear`, `edit`. Доменная модель
может продолжать использовать `Scene` и `Asset`; это не обязывает UI показывать
те же слова.

### Figma fidelity contract — Wardrobe and Create Look

Экраны продолжают эталон Chrome Kiss из Figma без создания параллельного
image-flow:

| Экран | Figma node | Reference viewport | Runtime owner |
|---|---|---:|---|
| Wardrobe / Pearl | `74:83` | `393×852` | `UserContentScreen`, `SceneRepository`, `UserContentController` |
| Create Look / Upload Photo | `94:248` | `393×852` | `CreateLookScreen`; после выбора — `UserImageController` |

Общий canvas — `#F4F2F6`, frame radius — `48`, content inset — `24`, ключевые
карточки имеют radius `32`. На reference viewport экран повторяет координаты
макета; на узком viewport и при enlarged text переходит в независимую
прокручиваемую композицию без масштабирования всего UI и без скрытия действий.
Wardrobe остаётся единой библиотекой built-in и пользовательских образов, а
`CreateLookScreen` возвращает только намерение `pickPhoto`: picker, crop,
сохранение и ошибки по-прежнему принадлежат существующему application workflow.

## Open Design Questions

1. Какое consumer-facing имя получает сам companion и может ли пользователь его
   переименовать?
2. Какой основной accent точнее передаёт Chrome Kiss после prototype review:
   hot orchid или более красный cherry pink?
3. Какая из трёх signature-концепций глаз становится основной?
4. Нужен ли current mood как явный текст или он должен читаться только через
   поведение и редкую contextual copy?
5. Как выглядит минимальная физическая рамка до появления hardware CAD и
   материалов корпуса?
6. Как объединить built-in и user looks в одной wardrobe, сохранив понятные
   edit/delete права?
7. Какой уровень Pearl Orbit допустим в светлой теме или специальных коллекциях,
   если основной canvas остаётся obsidian?
8. Какие collectible moments достаточно редки, чтобы не превратить стиль в
   Popstar Pet Club?
9. Какие typography candidates с сильной кириллицей нужно проверить на реальных
   строках и enlarged text?
10. Какие части foundation должны стать обязательными tokens после проверки трёх
    high-fidelity frames?
