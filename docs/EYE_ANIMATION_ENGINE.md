# Eye Animation Engine

> Процедурный рендеринг глаз, runtime-состояние и поведение анимации.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

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

Пример состояния:

```dart
class EyeRuntimeState {
  final double pupilX;
  final double pupilY;

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
  angry,
  sad,
  surprised,
  love,
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

Например:

```text
idle

wait random 2–7 sec

blink

wait random 1–5 sec

look left

wait

look center
```

За счёт этого персонаж визуально выглядит живым.

---

## Scene Renderer

Создаётся abstraction:

```dart
abstract interface class SceneRenderer {
  Widget buildPreview(
    Scene scene,
    DisplayProfile display,
  );
}
```

Реализации могут быть:

```text
ProceduralEyeRenderer
StaticImageRenderer
FrameAnimationRenderer
AnimalFaceRenderer
```

---
