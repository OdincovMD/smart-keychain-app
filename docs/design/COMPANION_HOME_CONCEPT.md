# Companion Home Concept — Chrome Kiss

> Статус: high-fidelity visual specification
>
> Направление: Chrome Kiss
>
> Secondary influence: Pearl Orbit
>
> Reference viewport: `390 × 844` logical px
>
> Дата: 2026-09-06
>
> Scope: visual concept only; документ не меняет Flutter-архитектуру или domain
> terminology

## Visual Thesis

Companion Home — не панель управления устройством, а портрет живого аксессуара.
Первое впечатление создаёт почти безрамочная чёрная линза с персонажем внутри.
Интерфейс окружает её как компактный fashion-object: один уверенный цветовой
жест, тонкий metal edge, короткая подпись состояния и небольшой гардероб.

Экран должен читаться в таком порядке:

1. **Character** — кто сейчас смотрит на пользователя.
2. **Mood / presence** — как персонаж себя чувствует и какой look надет.
3. **Primary interaction** — что можно сделать прямо сейчас.
4. **Wardrobe** — какие образы доступны рядом.
5. **Device status** — подключение и батарея без ощущения IoT-dashboard.

Chrome Kiss задаёт контраст, глянец и уверенность. Pearl Orbit добавляет только
мягкость света и precious-object restraint; он не превращает Home в жемчужную
витрину.

## Reference Frame

### First viewport anatomy

Спецификация использует `390 × 844` как контрольный кадр, но не требует
фиксированных координат в реализации. На других размерах сохраняются порядок,
относительный масштаб и зоны внимания.

| Zone | Reference bounds | Content | Visual weight |
|---|---:|---|---|
| Presence header | `y 20–74` | Имя companion/look слева; connection и battery справа | Low |
| Companion Stage | `y 78–430` | Крупная circular lens и живые глаза | Dominant |
| Presence line | `y 444–492` | Mood label и одна короткая фраза | Medium |
| Primary action | `y 506–562` | «Сменить образ» | Strong, below character |
| Wardrobe preview | `y 584–720` | Заголовок и горизонтальный rail из 3–4 look previews | Medium |
| Lower continuation | `y 736+` | Вход в коллекцию и secondary utilities ниже fold | Low |

System safe areas добавляются поверх этой схемы. На низком viewport уменьшается
вертикальная дистанция между зонами, но не диаметр character до размера обычной
карточки. Wardrobe может частично уходить за fold, оставляя видимыми заголовок и
верх previews как affordance продолжения.

```text
┌──────────────────────────────────────┐
│  LIVING EYES              ●  78%    │  presence header
│                                      │
│        ╭─ thin chrome edge ─╮        │
│      ╭────────────────────────╮      │
│     │      glossy black        │     │
│     │         ◖  ◗             │     │  Companion Stage
│     │      living surface      │     │
│      ╰────────────────────────╯      │
│                                      │
│  СПОКОЙНАЯ              LOOK 01      │  presence line
│  Сегодня просто рядом.               │
│                                      │
│  ╭─────── СМЕНИТЬ ОБРАЗ ─────────╮   │  primary action
│  ╰───────────────────────────────╯   │
│                                      │
│  ГАРДЕРОБ                    ВСЕ →   │
│  [ active ] [ look ] [ look ] [··   │  wardrobe rail
└──────────────────────────────────────┘
```

Схема объясняет иерархию, а не финальную форму glyphs или точную типографику.

## Companion Stage

### Physical representation

- Диаметр линзы: ориентир `300–326` logical px на viewport шириной `390`.
- Экран занимает не менее `90%` видимой фронтальной площади объекта.
- Physical rim — один тонкий `3–5 px` эквивалент, а не массивное цветное кольцо.
- Внешняя форма может иметь едва заметный нижний shadow/contact halo, но не
  должна становиться отдельным корпусом-карточкой.
- Линза — `#020205`, визуально глубже canvas `#0B0A0F`; граница различима через
  chrome edge и отражение, а не серую обводку.
- Крупный coral donut, верхняя петля и декоративный физический корпус из текущего
  simulator reference отсутствуют.
- Персонаж использует safe content region линзы; text и controls внутрь
  физического дисплея не помещаются.

### Lens material

Линза должна ощущаться выпуклой, но не фотореалистичной. Допустимы только три
сигнала материала:

1. тонкий liquid-silver edge с самым светлым участком в верхней левой четверти;
2. очень слабое внутреннее затемнение у нижнего правого края;
3. один короткий specular arc, не пересекающий глаза.

Запрещены полный radial rainbow, белая стеклянная полоса через всё лицо,
несколько бликов одинаковой силы и blur-heavy glow. Character остаётся самым
контрастным объектом внутри линзы.

### Controlled asymmetry

- Центр линзы смещён на `6–10 px` влево относительно геометрической оси.
- Status cluster компенсирует это смещение справа в presence header.
- Specular arc живёт только в верхней левой четверти.
- Активный Wardrobe tile может начинаться с левого поля, а последний tile
  намеренно обрезается справа.
- Глаза имеют собственную мягкую асимметрию, но Stage не наклоняется и не
  превращается в динамический poster.

Асимметрия создаёт editorial posture; основные tap targets и читаемая copy
остаются предсказуемыми.

## Composition and Focus

### Primary focal point

Взгляд character — единственный первичный focal point. Высокий локальный
контраст глаз на `#020205`, спокойная зона вокруг и большой размер линзы должны
перехватывать внимание раньше title, button или battery.

### Secondary focal points

1. Mood/presence line — объясняет состояние увиденного character.
2. Primary action — продолжает relationship loop, не конкурируя с лицом.
3. Active look в Wardrobe — связывает companion с коллекцией.

Device status остаётся tertiary. Он должен быть доступен при сканировании, но не
формировать самостоятельный card, badge-row или dashboard header.

### Negative space

- Между safe edge viewport и lens: не менее `20 px` визуального воздуха.
- Между lens и presence line: ориентир `16–20 px`.
- Между copy и primary action: ориентир `18–24 px`.
- Вокруг глаз внутри lens сохраняется не менее `18%` диаметра свободного поля.
- Никаких labels, badges или control overlays поверх character.
- Между крупными зонами используется свободный `color.canvas`, а не вложенные
  surfaces.

Negative space здесь передаёт уверенность и ценность объекта, но не должен
скрывать wardrobe за несколькими пустыми экранами.

## Relationship Between Character and Controls

- Primary action стоит сразу после mood copy: сначала пользователь считывает
  присутствие, затем получает понятное продолжение «Сменить образ».
- Wardrobe preview расположен под action и показывает содержание действия до
  перехода на отдельный экран.
- Active Wardrobe tile визуально рифмуется с текущим look через Icy Lilac marker,
  а не через рамку вокруг всего блока.
- При выборе look character может коротко направить внимание к rail, но не
  реагирует на каждый scroll tick.
- Brightness не находится между character и wardrobe. Доступ к ней — compact
  utility glyph или secondary material sheet ниже основного relationship loop.
- Connection и battery не вызывают character reaction при каждом rebuild;
  эмоциональная реакция допустима только на значимое подтверждённое событие.

## Material and Color Placement

Значения semantic roles для Obsidian и Pearl определены в `DESIGN.md`. Home не
выбирает appearance-specific hex напрямую.

| Semantic role / material | Exact role on Home | Limits |
|---|---|---|
| `color.canvas` | Полный app canvas и negative space | Не дробить на чередующиеся cards |
| `color.lens` | Только живая поверхность Companion Stage | Не осветлять в Pearl и не использовать как универсальный button fill |
| `color.material.chrome` | Тонкий rim, essential edge в Pearl, редкая кромка active control | Не обводить каждый tile и icon |
| `color.accent.primary` | Primary action, current-action marker, короткий applying pulse | Не заливать Stage, header или весь wardrobe |
| `color.accent.optical` | Active look detail и optical trace | На Pearl не использовать как единственный selected-state signal |
| `color.material.champagne` | Редкий Pearl Orbit glint или collectible marker | Не использовать как второй постоянный CTA |
| `color.text.primary` | Имя, action label, важная copy | Не делать всё uppercase |
| `color.text.secondary` | Mood sentence, status details, utility labels | Проверять контраст на соответствующей surface |

### Pearl appearance on the same Home layout

Pearl сохраняет все bounds, visual hierarchy, negative space и controlled
asymmetry reference-экрана. Меняется только экспозиция материалов:

- app canvas становится мягким rose-pearl off-white, но секции не превращаются
  в белые карточки;
- неизменная glossy black CompanionStage lens сильнее отделяется от фона и
  выглядит как вставленный optical jewel;
- основной текст становится глубоким plum-black, secondary copy — спокойным
  mauve-gray;
- chrome rim использует более тёмный базовый тон и тот же единственный верхний
  specular highlight;
- Hot Orchid остаётся primary action. Текст на нём использует
  `color.text.onAccent`, а различимая chrome/dark edge компенсирует недостаточный
  `2.69:1` контраст Orchid к Pearl canvas;
- Icy Lilac остаётся внутри black lens либо дополняется тёмным shape/marker на
  светлом canvas; он не работает как одинокая selection outline;
- secondary surfaces отличаются мягким pearl tone, divider остаётся тихим и не
  создаёт сетку из рамок;
- character pose, typography, spacing, wardrobe order и motion полностью
  совпадают с Obsidian.

Pearl — не дневная версия с белым корпусом вокруг каждой функции. Контрастная
чёрная линза по-прежнему доминирует, а светлый canvas делает её более
jewel-like, не меняя relationship loop.

### Specular rule

Specular highlight разрешён только:

- на верхней левой части lens rim;
- на одном optical detail внутри утверждённого character signature;
- на коротком confirmation glint после успешно применённого look.

Он запрещён на тексте, каждом tile, status glyphs и disabled/error states. Один
кадр должен иметь один доминирующий источник света.

## Primary Interaction

### Jewel action

«Сменить образ» — широкая, но не full-card action высотой около `52–56 px`.
Основа Hot Orchid, label использует `color.text.onAccent`, кромка — различимый
appearance-aware chrome tone. Форма может быть stretched capsule с чуть более
собранными боками, чтобы не выглядеть стандартным Material pill.

Состояния:

- **Idle:** плотная Orchid surface, без постоянного glow.
- **Pressed:** небольшая material compression, не масштабирование всего layout.
- **Applying:** label меняется на «Примеряем…», насыщенность Orchid слегка
  снижается, по кромке проходит один controlled light trace.
- **Success:** краткий optical glint связывает action и Stage только после
  подтверждения repository operation.
- **Failure:** action возвращается в idle; понятная error copy появляется
  отдельно. Character не изображает success.

## Wardrobe Preview

Wardrobe — горизонтальный rail без большой enclosing card.

- Заголовок и короткое «Все» стоят на baseline выше previews.
- Видно `2.6–3.4` tile: частичный последний tile сообщает о горизонтальном
  продолжении.
- Tile опирается на thumbnail/look, а не на текстовый rectangle.
- Active tile получает Icy Lilac trace и короткую подпись; неактивные не имеют
  одинаковых тяжёлых borders.
- Built-in и user-generated looks могут жить в одном visual language; ownership
  обозначается micro-label только там, где это помогает действию.
- Empty state заменяет rail одной строкой «Собери первый образ» и compact action
  «Добавить фото», не создавая большую иллюстративную card.

## Secondary Device Status

Connection и battery размещаются компактным cluster в правой части presence
header:

- connection: точка/малый glyph + доступный text label в semantics;
- battery: icon + `78%` без отдельного огромного pill;
- disconnected: neutral outline и ясная copy, а не красный alarm по всему Home;
- charging в будущем: изменение glyph, не постоянная flashing-анимация.

Имя текущего look или companion занимает левую часть header. Техническое имя
устройства доступно ниже fold или в settings, если оно не совпадает с
consumer-facing именем.

## Brightness Placement

Brightness остаётся функционально доступной, но не является hero-control:

- compact light glyph рядом с secondary utilities либо вход в MaterialSheet;
- текущее значение не показывается постоянно, если пользователь его не меняет;
- slider живёт в sheet/quick settings и не занимает первый viewport;
- character preview остаётся видимым во время настройки, если это возможно без
  нарушения accessibility.

## Companion Home States

### 1. Neutral idle

| Layer | Specification |
|---|---|
| Character | Центральный мягкий gaze, signature neutral, редкие micro-saccades и естественный blink |
| Accent | Hot Orchid на primary action; Icy Lilac только на active look |
| Copy | Mood label «СПОКОЙНАЯ»; presence «Сегодня просто рядом.» |
| Motion | Длинные спокойные pauses; UI chrome неподвижен |
| Wardrobe | Текущий look отмечен; rail остаётся доступен для browse |

### 2. Look selected / applying

| Layer | Specification |
|---|---|
| Character | Короткий curious glance к выбранному tile; текущая анатомия сохраняется до подтверждения apply |
| Accent | Icy Lilac отмечает selection; Hot Orchid action переходит в controlled applying state |
| Copy | До действия: «Этот тебе идёт»; во время операции: «Примеряем…» |
| Motion | Anticipation у character, один action trace; success reaction только после подтверждения |
| Wardrobe | Selected и current различаются: selected — Lilac trace, current — устойчивый micro-marker; на success они объединяются |

При ошибке selected state может сохраниться для повторной попытки, current look
не меняется, а infrastructure exception никогда не показывается пользователю.

### 3. Sleepy / low-energy

| Layer | Specification |
|---|---|
| Character | Более тяжёлые верхние веки, gaze немного вниз, медленный blink; silhouette остаётся signature |
| Accent | Тот же Hot Orchid и Icy Lilac, но локальные decorative glints приглушены; тема целиком не перекрашивается |
| Copy | Mood label «СОННАЯ»; presence «Сегодня помедленнее.» |
| Motion | Реже actions, больше pauses, никакого bounce |
| Wardrobe | Функционально без изменений; active marker не исчезает и contrast не снижается |

Mood меняет character, одну строку copy и локальную интенсивность motion. Canvas,
navigation, semantic colors и структура Home остаются стабильными.

## Color Decision: Hot Orchid vs Cherry Pink

Для сравнения Cherry Pink зафиксирован как concept swatch `#FF3F6C`. Это не
новый design token и не изменение `DESIGN.md`.

| Criterion | Hot Orchid `#FF4FB8` | Cherry Pink `#FF3F6C` |
|---|---|---|
| Mood | Magnetic, glam, synthetic, уверенно playful | Более дерзкий, сочный, романтичный и телесный |
| Chrome Kiss fit | Подчёркивает digital-fashion и контрастирует с cold chrome | Хорошо поддерживает kiss, но уводит ближе к cosmetics/lipstick |
| Contrast on Obsidian `#0B0A0F` | `6.63:1` | `5.80:1` |
| Premium / playful | Premium остаётся ведущим, playful — в насыщенности | Playful и эмоциональность выходят вперёд |
| Pairing with Icy Lilac | Чёткая hot/cold пара без ощущения флага | Более резкий трёхцветный конфликт с Lilac и semantic red |
| Main risk | При избытке становится generic neon-pink app | Может читаться как danger, sale или beauty-brand red-pink |

Оба solid swatch проходят WCAG AA для нормального текста при паре с Obsidian,
но это не отменяет проверки реальных размеров, состояний и compositing.

### Recommendation

**Для Companion Home reference выбрать Hot Orchid `#FF4FB8`.** Он точнее
удерживает Chrome Kiss между premium optical object и playful companion, лучше
контрастирует с Obsidian и меньше конфликтует с будущим danger color. Cherry Pink
может остаться кандидатом для отдельной collectible capsule или editorial
campaign, но не основным Home accent.

Рекомендация не изменяет существующие tokens автоматически.

## Typography Candidates

Шрифты не добавляются в repository. До выбора обязательны реальные кириллические
specimens на словах «Сменить образ», «Настроение», «Гардероб», «Подключено» и на
цифрах battery.

### Display candidates

| Candidate | Character | Fashion relevance | Cyrillic / readability | Childish-look risk |
|---|---|---|---|---|
| **Unbounded** | Широкий variable display sans, футуристичный без sci-fi HUD | Сильный modern Y2K и collectible-label posture | Cyrillic и Cyrillic Extended; хорош для коротких строк, но требует сдержанного width/weight | Medium: тяжёлый вес и all-caps могут стать gamer/bubble |
| **Cormorant Garamond** | Высококонтрастный editorial serif с мягкой пластикой | Самый fashion/editorial; усиливает Pearl Orbit | Развитая Cyrillic; только крупные короткие заголовки, не controls и не мелкий status | Low childish, Medium perfume-brand / conventional luxury |
| **Commissioner** | Variable grotesk с управляемым flare и человеческими деталями | Позволяет дозировать glam через форму, оставаясь digital | Cyrillic Plus/Pro; наиболее универсален между display и короткой UI-copy | Low; главный риск — слишком нейтральный результат при нулевом flare |

Проверенные источники: [Unbounded в Google Fonts](https://github.com/google/fonts/blob/main/ofl/unbounded/upstream_info.md),
[Cormorant project FONTLOG](https://github.com/CatharsisFonts/Cormorant/blob/master/FONTLOG.txt),
[Commissioner repository](https://github.com/kosbarts/Commissioner).

**Первый specimen pairing для Chrome Kiss:** Unbounded в коротких display roles
с умеренным weight + нейтральный Manrope для UI. Это направление для визуального
теста, не утверждение font dependency.

### Body / UI grotesks

| Candidate | Why it fits | Watch-outs |
|---|---|---|
| **Manrope** | Чистая геометрия, мягкие детали и улучшенная Cyrillic; поддерживает Chrome Kiss без конкуренции с display | На слишком лёгком weight становится стерильным, на слишком круглом tracking — generic startup |
| **Golos Text** | Сильная экранная читаемость и естественная кириллица; хорошо работает в status, sheets и длинной copy | Более утилитарен; fashion identity должен приходить от display, composition и materials |

Источники: [Manrope FONTLOG](https://github.com/google/fonts/blob/main/ofl/manrope/FONTLOG.txt),
[Golos Text repository](https://github.com/googlefonts/golos-text).

## Product Language Options

Domain names `Scene` и `AutomationRule` остаются неизменными. Ниже — только
consumer-facing vocabulary.

| Domain concept | Option 1 | Option 2 | Option 3 | Home recommendation |
|---|---|---|---|---|
| Scene | **Образ** | Вайб | Экран | **Образ** — понятно связывает character и wardrobe |
| My Content | **Мои образы** | Гардероб | Моя коллекция | **Мои образы** в navigation; «Гардероб» как section title |
| Apply | **Надеть** | На экран | Применить | **Надеть** в wardrobe; «Сменить образ» на Home |
| Mood | **Настроение** | Состояние | Вайб | **Настроение** — яснее и не звучит технически |
| Automations | **Ритуалы** | Сценарии | По расписанию | **Ритуалы** как brand term, с explanatory subtitle при первом входе |

Usage examples:

- «Сменить образ» — Home primary action.
- «Надеть» — подтверждение конкретного выбранного look.
- «Мои образы» — стабильный navigation label.
- «Гардероб» — живой заголовок rail/collection.
- «Настроение: сонное» — accessibility-friendly state phrase.
- «Ритуалы» + subtitle «Образы по времени и событиям» — если функция появится.

Не использовать «скин», «контент», «активировать», «пресет» и чрезмерно
антропоморфные команды вроде «наряди малышку». Copy остаётся короткой,
уверенной и дружелюбной без infantilization.

## Accessibility and Responsive Constraints

- Character mood всегда дублируется readable copy и semantics.
- Status не передаётся только цветной точкой.
- Dynamic text не должен перекрывать Stage; при большом text scale wardrobe
  уходит ниже fold, а primary action и mood copy сохраняются.
- Minimum tap targets определяются platform accessibility rules, даже если
  visual glyph меньше.
- Reduced motion сохраняет три состояния через pose, copy и selected markers;
  specular trace заменяется мгновенным material-state change.
- Orchid и Lilac не используются как единственная разница current/selected.
- Lens rim не должен снижать контраст глаз или создавать flashing edge.

## Explicit Non-goals

- Это не Flutter layout specification и не перечень widgets.
- Документ не меняет Scene/Device contracts и не задаёт BLE behaviour.
- Он не утверждает hardware dimensions, material finish или physical loop.
- Он не добавляет font files, gradients, raster assets или dependencies.
- Он не утверждает финальный character signature; выбор вынесен в
  `CHARACTER_SHEET.md`.

## Open Questions

1. Должно ли consumer-facing имя companion быть отдельным от имени устройства?
2. Показывать ли mood label постоянно или только при смене/первом открытии?
3. Достаточно ли одного primary action «Сменить образ», если active tile уже
   выбран в rail?
4. Должен ли active look иметь имя в presence header или только под character?
5. Какой минимальный диаметр Stage сохраняет premium presence на compact Android?
6. Где удобнее открыть brightness: из status cluster или из нижнего utility
   sheet?
7. Нужна ли Cherry Pink отдельная роль для limited collections, не смешанная с
   semantic danger?
8. Какой typography pairing выигрывает после сравнения кириллических specimens
   на реальном viewport?
9. Насколько заметным может быть Pearl Orbit champagne glint, не создавая второй
   competing accent?
