# Chrome Kiss Motion Language

> Статус: design foundation, implementation not started

Motion в Smart Keychain поддерживает две разные, но связанные системы:

1. **Character Motion** создаёт ощущение жизни.
2. **Interface Motion** объясняет действие, сохраняет пространственную связь и
   добавляет тактильность.

Интерфейс не имитирует движения персонажа. Персонаж может быть органичным и
непредсказуемым; UI остаётся быстрым, уверенным и управляемым.

## Motion Thesis

Chrome Kiss движется как маленький живой объект в точном fashion-tech
инструменте: character дышит паузами и несовершенством, interface отвечает
коротким magnetic snap, а редкий specular glint подтверждает важный момент.

Каждое движение должно выполнять хотя бы одну функцию:

- feedback;
- orientation;
- continuity;
- deliberate delight.

Если движение не выполняет ни одну из них, оно не используется.

## Character Motion

Character Motion принадлежит живому экрану, а не всему интерфейсу.

- Вероятностные idle actions важнее фиксированного loop.
- Паузы так же важны, как движение; персонаж не должен быть гиперактивным.
- Gaze использует лёгкую anticipation, ускорение, едва заметный overshoot и
  settle.
- Blink имеет варианты и малую асимметрию.
- Micro-saccades предотвращают абсолютную неподвижность, но не привлекают
  внимание сами по себе.
- Mood изменяет частоту, амплитуду и характер действий, а не запускает отдельный
  «GIF».
- Special action получает контроль временно и возвращается в mood/idle.
- Реакции на продуктовые события редки и подчиняются reaction hierarchy.

Character не реагирует на каждый tap, scroll или изменение slider. Частая
реактивность превращает companion в декоративный UI-индикатор и уничтожает
ощущение самостоятельной жизни.

## Interface Motion

### Fast magnetic snap

Selection, toggle и короткое state change быстро притягиваются к целевому
состоянию. Начало ощущается немедленным, завершение — точным. Долгое плавное
«плавание» не соответствует confident temperament.

### Short spring

Допустим один небольшой overshoot для JewelButton, selected LookTile или
MaterialSheet. Spring не должен выглядеть резиновым, bounce многократно
повторяться или задерживать доступность действия.

### Optical continuity

Объект, который остаётся тем же между состояниями, не телепортируется. Preview
look, selection edge и Companion Stage должны восприниматься как одна связанная
система. Направление перехода соответствует расположению источника.

### Restrained glint

Короткий specular highlight возможен после подтверждённого apply/save/pairing.
Он проходит по материально объяснимой кромке и не является постоянной loop
анимацией.

### Tactile press response

Press начинается сразу, даёт небольшое изменение масштаба/света и быстро
возвращается. Label остаётся читаемым, а touch target — стабильным. Feedback не
ждёт завершения network/device operation.

## Duration Categories

Категории являются диапазонами восприятия, а не привязкой к Flutter API.

| Category | Draft duration | Use | Character |
|---|---:|---|---|
| Micro | `80–120 ms` | Press, icon swap, tiny status feedback | Немедленный, tactile |
| Interaction | `140–220 ms` | Look selection, compact control, active marker | Magnetic, precise |
| Transition | `240–360 ms` | MaterialSheet, page continuity, stage content change | Уверенный, один settle |
| Delight | `450–800 ms` | Pairing success, rare collectible beat, special acknowledgement | Выразительный, но не блокирующий |

Routine interaction стремится оставаться короче `300 ms`. Distance и visual
mass могут увеличить duration, но не превращают частое действие в шоу.

Enter и exit не обязаны быть зеркальными. Закрытие временной поверхности обычно
короче открытия. Все анимации должны корректно retarget при быстром повторном
действии, а не начинаться заново из устаревшего состояния.

## Motion Tokens

| Token | Meaning |
|---|---|
| `motion.micro` | Press и мгновенный feedback |
| `motion.interaction` | Selection и обычная смена состояния |
| `motion.transition` | Spatial continuity между связанными поверхностями |
| `motion.delight` | Редкий branded moment |
| `motion.curve.magnetic` | Быстрый старт и точный settle |
| `motion.curve.material` | Появление/закрытие физической surface |
| `motion.curve.character` | Органичное движение с anticipation/overshoot |

Конкретные curves и spring-параметры выбираются только при motion prototype и
проверяются на реальном Flutter frame scheduling.

## Apply Look Choreography

```text
LookTile
  ↓ selection acknowledged
Selected edge / marker appears
  ↓ optical continuity
Companion Stage adopts the new look
  ↓ repository/device confirmation
Tiny success highlight
  ↓
Stable current-look state
```

### 1. Selection

Tap немедленно меняет selected marker через Interaction motion. Preview не
исчезает и не прыгает. Повторный выбор текущего look не запускает celebration.

### 2. Commitment

Если выбор и применение разделены, primary action находится рядом с выбранным
look и явно называет результат. Busy state не стирает выбранный preview.

### 3. Visual continuity

Связь LookTile и Companion Stage передаётся общей оптической кромкой, направлением
или кратким material transition. Не нужно физически переносить всю карточку
через экран, если это создаёт layout cost или визуальный шум.

### 4. Stage change

Новый look появляется внутри той же LensSurface. Для совместимого контента
используется короткий controlled crossfade/morph; несовместимые renderer types
могут сменяться с минимальным opacity transition без ложной геометрической
интерполяции.

### 5. Confirmation

Только после подтверждения операции Stage и LookTile получают короткий chrome
или icy-lilac glint. Feedback находится возле результата, а не только в далёком
toast.

### 6. Failure

При ошибке прежний подтверждённый look остаётся на Stage. Selected item получает
понятное error state и доступный next action. Success motion никогда не
запускается до фактического успеха.

## Other Product Moments

### Pairing

Объект становится присутствующим: lens получает глубину, character просыпается,
primary action подтверждается на месте. Полноэкранный confetti не нужен.

### Save image

Crop preview сохраняет позицию, становится новым LookTile и присоединяется к
Wardrobe. Редкий glint допустим на новом tile; персонаж может коротко проявить
любопытство, но только после успешного сохранения.

### MaterialSheet

Появляется от связанного trigger или нижней кромки, сохраняет spatial context и
закрывается быстрее, чем открывается. Sheet и backdrop движутся как одна пара.

### Status changes

Battery/connection используют micro transition и понятный label/icon. Потеря
связи не должна вызывать playful bounce или sparkle.

### Destructive action

Confirmation остаётся спокойным и точным. Danger не получает delight motion.
После удаления коллекция мягко закрывает освободившееся место, сохраняя focus и
reading order.

## Reaction Hierarchy

| Level | Event | Character response |
|---|---|---|
| 0 — none | Scroll, brightness drag, повторный tap, открытие обычной настройки | Нет реакции |
| 1 — acknowledge | Успешный apply look, сохранение image | Короткий взгляд или изменение openness |
| 2 — state change | Connection restored/lost, значимое настроение | Ясная, но короткая реакция |
| 3 — delight | Первое pairing, редкий collectible milestone | Один special beat, затем возврат к idle |

Одновременно выполняется не больше одной событийной реакции. Она не должна
ломать текущий mood или бесконечно откладывать idle behaviour.

## Reduced Motion

Reduced-motion mode сохраняет смысл каждого действия:

- LookTile сразу получает selected marker без spatial travel или spring.
- Companion Stage меняет контент немедленно либо через короткий restrained
  opacity transition, если он не вызывает дискомфорт.
- Specular sweep, sparkle и collectible delight отключаются.
- Character показывает стабильную центральную позу текущего mood; обязательные
  state changes применяются без перехода.
- Apply success подтверждается иконкой, текстом и состоянием tile, а не motion.
- MaterialSheet появляется без крупного перемещения или через минимальный fade.
- Focus, semantics и порядок действий остаются идентичными обычному режиму.

Reduced motion — полноценный эквивалент, а не урезанный режим без feedback.

## Performance and Quality Guardrails

- Не запускать loop motion у декоративных interface-элементов.
- Не использовать blur, glow или сложный shader как обязательную часть частого
  interaction feedback.
- Не анимировать несколько вложенных containers одновременно ради одного
  появления.
- Не менять layout без необходимости; optical continuity не должна провоцировать
  скачки текста или touch targets.
- Character и interface не конкурируют за внимание одновременными крупными
  движениями.
- Motion проверяется при быстрых повторных действиях, interruption, background /
  foreground lifecycle и на минимальном целевом устройстве.
- Заявление о стабильном FPS допускается только после profile measurement.

## Do Not Animate

- каждый scroll reveal;
- каждый текст при первом появлении;
- технический status как celebration;
- background glow в бесконечном цикле;
- hearts или sparkles после обычного tap;
- error через playful bounce;
- character в ответ на каждый UI control;
- несколько конкурирующих glint одновременно.

## Open Motion Questions

1. Какая степень spring/overshoot ощущается magnetic, а не rubbery?
2. Должен ли Apply Look запускаться сразу по tap или после отдельного commitment?
3. Как обеспечить visual continuity между static, user image и procedural look
   без ложного morph?
4. Какая реакция персонажа на connection loss остаётся эмоциональной, но не
   тревожной?
5. Какие delight moments достаточно редки для collectible-ощущения?
6. Какой минимальный reduced-motion fade комфортен целевой аудитории?
