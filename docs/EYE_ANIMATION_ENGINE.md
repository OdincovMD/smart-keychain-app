# Emotive Eye Engine

> Собственный процедурный character system для виртуального экрана брелока.

> Статус: Emotive Eye Engine V1 реализован. Визуальная выразительность роботов
> используется только как общий принцип; чужие assets, формы глаз и animation
> timing не копируются.

## Архитектурная граница

```text
Scene(ProceduralEyesContent)
  → ProceduralEyesSceneRenderer
  → ProceduralEyesView
  → EyeBehaviourEngine(EyeCharacter)
  → EyeBehaviourAction
  → EyeRuntimeState
  → EyePaintScene
  → ProceduralEyePainter
```

`Scene → Renderer` остаётся общей границей со статичными и пользовательскими
сценами. Eye domain не импортирует Flutter и не определяет протокол будущего
физического дисплея.

## EyeCharacter и moods

`EyeCharacter` хранит стабильные настройки собственного персонажа.
`EyeMoodProfile` изменяет базовую позу и вероятности поведения, а не выбирает
готовый GIF.

Поддерживаются moods:

- `neutral` — спокойный сбалансированный idle;
- `happy` — мягкий прищур, приподнятые уголки и немного более живой темп;
- `sleepy` — опущенный взгляд, медленные движения и повышенный вес slow blink;
- `curious` — открытый взгляд, чуть более крупные зрачки и больше gaze actions;
- `annoyed` — сдержанный прищур, более редкие направленные движения;
- `surprised` — увеличенная форма глаз, уменьшенные зрачки и быстрый gaze.

## Runtime state

`EyeRuntimeState` — immutable Flutter-free pose:

- gaze X/Y;
- независимая открытость левого и правого века;
- pupil scale и eye scale X/Y;
- expression tilt и vertical offset;
- velocity X/Y;
- `EyeMotionPhase` для idle, anticipation, movement, blink и special action;
- текущий mood (`EyeEmotion` сохранено как совместимое имя scene API,
  `EyeMood` — domain alias).

Никакие `AnimationController`, `Curve`, `Timer` или `BuildContext` в domain не
передаются.

## Behaviour model

`EyeBehaviourEngine` получает внедряемый `Random`. Production использует
естественную случайность; тесты и debug могут задать seed.

Weighted scheduler выбирает:

- idle pause;
- normal blink;
- double blink;
- slow blink;
- look left/right/slightly up/slightly down;
- почти незаметную micro-saccade;
- return to center.

Диапазон idle зависит от mood и составляет примерно 1.05–4.8 секунды. Если
моргания слишком долго не было, engine принудительно выбирает blink. Поэтому нет
фиксированного цикла «моргать каждые N секунд», а sleepy и curious действительно
ведут себя по-разному.

## Motion model

Направленный gaze выполняется как:

```text
small anticipation
  → accelerated movement
  → subtle overshoot
  → settle
  → variable hold
  → smooth return to mood center
```

Micro-saccades используют ту же модель с амплитудой до 12% gaze range. Blink
получает небольшой seeded left/right lead в 8–18 мс и разную геометрию век, но
оба глаза всегда возвращаются в открытую mood pose.

## Special actions

`playSpecialAction(...)` временно прерывает idle. V1 содержит оригинальное
действие `fireflySearch`: персонаж замечает воображаемый огонёк, прослеживает его
в двух точках и плавно возвращается в текущий mood. Это не копия поведения или
timing какого-либо коммерческого робота.

## Flutter runtime и performance

- основной preview владеет ровно одним `AnimationController`;
- один одноразовый `Timer` существует только между action/hold этапами, таймера
  на каждый frame нет;
- controller передан в `CustomPainter.repaint`, поэтому каждый кадр не проходит
  через Riverpod и widget rebuild;
- `EyePaintScene` — единый immutable input painter-а;
- `Paint` и базовые `RRect` создаются один раз в painter constructor/static;
- renderer использует логическое поле и масштабируется по фактическому размеру
  `VirtualScreen`; круглая safe region задаётся относительным inset, а не
  физическим hardware resolution;
- `RepaintBoundary` изолирует procedural screen;
- при `disableAnimations` scheduler и ticker останавливаются, отображается
  стабильная mood pose;
- `dispose()` отменяет pending timer/completer и освобождает ticker.

Карточка сцены создаёт `ProceduralEyesView(animate: false)` и не запускает
бесконечную анимацию.

## Debug controls

Только в debug-сборке simulator sheet предоставляет:

- выбор mood;
- normal/double blink;
- look left/right;
- `fireflySearch` special action;
- natural random или deterministic seed 7/42.

Riverpod хранит только эти редкие намерения. Runtime pose и per-frame state в
provider не публикуются.
