# Eye Animation Engine

> Процедурный рендеринг глаз, runtime-состояние и поведение анимации.

> Статус: Living Eyes v0.1 реализован в виртуальном устройстве.

## Реализованная граница v0.1

- одна built-in сцена `living_eyes_v1`, активная по умолчанию;
- собственный процедурный образ на поле 240×240;
- эмоции `neutral`, `happy`, `sleepy`, `surprised`;
- автономные gaze, blink и double blink;
- debug-переключение эмоции и ручное моргание;
- статичная neutral-поза при отключённых анимациях;
- Flutter renderer существует только для app preview и не определяет формат
  будущего физического устройства.

## Подход к рендерингу

Для анимированных глаз предпочтительно разработать собственный procedural renderer.

Основной кандидат:

```text
Flutter CustomPainter
```

Это позволит программно контролировать:

- форму глаз;
- положение зрачков;
- размер зрачков;
- моргание;
- направление взгляда;
- эмоцию;
- движение век;
- цвет;
- случайные движения.

---

## Eye Runtime State

Runtime-состояние:

```dart
class EyeRuntimeState {
  final double gazeX;
  final double gazeY;
  final double eyelidOpen;
  final double pupilScale;
  final EyeEmotion emotion;
}
```

---

## Eye Emotion

```dart
enum EyeEmotion {
  neutral,
  happy,
  sleepy,
  surprised,
}
```

---

## Eye Behaviour

Глаза не должны обязательно воспроизводить короткий одинаковый GIF по кругу.

Может использоваться behaviour engine:

```text
IDLE
 │
 ├── random blink
 │
 ├── random look left
 │
 ├── random look right
 │
 ├── double blink
 │
 └── special animation
```

В v0.1 используется один последовательный scheduler:

```text
wait random 1.2–3.6 sec

55% gaze / 35% blink / 10% double blink

force blink after 6.5 sec without a blink

gaze target → hold → return center
```

За счёт этого персонаж визуально выглядит живым.

Случайность внедряется в `EyeBehaviourEngine`, поэтому одинаковый seed даёт
одинаковую последовательность в тестах.

---

## Runtime и renderer

Фактический поток v0.1:

```text
Scene
  → EyeBehaviourEngine
  → EyeRuntimeState
  → ProceduralEyesView
  → EyePaintScene
  → ProceduralEyePainter
```

- `ProceduralEyesView` владеет единственным `AnimationController` и таймерами;
- `EyeBehaviourEngine` не импортирует Flutter;
- `EyePaintScene` — immutable input painter-а;
- `ProceduralEyePainter` не читает Riverpod, `BuildContext` и wall clock;
- кадры идут через `CustomPainter.repaint`, без rebuild дерева;
- карточка сцены использует тот же painter в замороженной позе.

Riverpod хранит только debug-намерения: выбранную эмоцию и revision ручного
моргания. Per-frame состояние через Riverpod не проходит.

---
