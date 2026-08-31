# Автоматизации

> Триггеры, действия, движок правил, погода и ограничения фоновой работы.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Automation Domain Model

```dart
class AutomationRule {
  final String id;

  final String name;

  final bool enabled;

  final AutomationTrigger trigger;

  final AutomationAction action;
}
```

---

## Automation Trigger Types

Первая архитектура:

```text
TimeTrigger
WeatherTrigger
BatteryTrigger
ManualTrigger
```

В будущем:

```text
LocationTrigger
CalendarTrigger
MotionTrigger
ChargingTrigger
NotificationTrigger
```

Некоторые hardware triggers должны выполняться прошивкой, а не телефоном.

---

## Automation Actions

Начально:

```text
SetSceneAction
SetBrightnessAction
```

Позже:

```text
PlayTemporaryScene
RestorePreviousScene
```

---

## Automation Engine

```text
External/Internal Event
        ↓
AutomationEngine
        ↓
matching rules
        ↓
Action
        ↓
DeviceRepository
```

Например:

```text
WeatherService

RAIN
 ↓

AutomationEngine

rule #5 matches
 ↓

SetSceneAction("rain-eyes")
 ↓

DeviceRepository.setScene(...)
```

AutomationEngine не знает, является устройство виртуальным или физическим.

---

## Weather Architecture

Погода не должна быть частью DeviceRepository.

Структура:

```text
LocationProvider
      ↓
WeatherRepository
      ↓
WeatherState
      ↓
AutomationEngine
```

Device получает только результат.

Например:

```text
Weather API:

code = rain
```

преобразуется:

```dart
WeatherCondition.rain
```

а далее:

```text
rain
 ↓
AutomationRule
 ↓
scene = rainy-eyes
```

Координаты устройства не передаются.

---

## Weather Domain State

Нужно нормализовать внешние weather providers.

```dart
enum WeatherCondition {
  clear,
  cloudy,
  rain,
  snow,
  fog,
  thunderstorm,
  unknown,
}
```

Это защищает приложение от API-specific weather codes.

---

## Weather Provider Abstraction

```dart
abstract interface class WeatherRepository {
  Future<WeatherSnapshot> getWeather(
    GeoPosition position,
  );
}
```

Конкретный Weather API выбирается позднее.

Это позволит сменить provider без изменения automation engine.

---

## Background Processing

Background execution не является частью MVP v0.1.

Архитектура должна поддерживать его позднее.

Нельзя строить основную работу устройства на предположении:

```text
mobile app runs forever
```

Физическое устройство должно уметь продолжать отображение активной scene после отключения телефона.

---
