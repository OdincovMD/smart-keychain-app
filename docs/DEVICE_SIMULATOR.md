# Virtual Device Simulator

> Контракт, состояние и средства тестирования виртуального брелока.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Назначение и статус

Virtual Device Simulator является полноценной частью архитектуры, а не временным `if`.

Он должен сохраниться в проекте после появления настоящего устройства.

Назначение:

- разработка без hardware;
- автоматизированные тесты;
- разработка UI;
- воспроизведение edge cases;
- тестирование автоматизаций;
- демонстрация продукта;
- debugging.

---

## Virtual Device Components

```text
VirtualDeviceRepository
          │
          ▼
 VirtualDeviceEngine
          │
     ┌────┼─────────────┐
     │    │             │
     ▼    ▼             ▼
 Display State     Battery State
 Storage State     Connection State
```

Основные компоненты:

```text
VirtualDeviceRepository
VirtualDeviceEngine
VirtualDeviceState
VirtualDisplayController
VirtualStorage
VirtualBattery
VirtualConnection
```

---

## Virtual Device State

Пример:

```dart
class VirtualDeviceState {
  final bool connected;

  final int batteryPercent;

  final double brightness;

  final String? activeSceneId;

  final List<String> installedAssets;

  final int storageUsed;

  final int storageTotal;
}
```

---

## Virtual Screen

В приложении создаётся виджет:

```text
VirtualScreen
```

который имитирует физический круглый экран.

Он НЕ является основным UI приложения.

Это preview физического устройства.

Концептуально:

```text
┌──────────────────────────────┐
│                              │
│              ╭──────╮        │
│             │        │       │
│             │  👀   │       │
│             │        │       │
│              ╰──────╯        │
│                              │
└──────────────────────────────┘
```

---

## Virtual Screen Responsibilities

`VirtualScreen` отвечает только за отображение.

Он получает:

```text
Scene
+
DisplayProfile
+
SceneRuntimeState
```

и отрисовывает результат.

Он не должен:

- обращаться в database;
- подключаться к Bluetooth;
- получать Weather API;
- сам выбирать scene;
- управлять автоматизациями.

Правильно:

```text
Automation
    ↓
setScene(rain)
    ↓
DeviceRepository
    ↓
VirtualDeviceState
    ↓
VirtualScreen
```

---

## Simulator Controls

В developer mode должны существовать средства управления simulator.

Например:

```text
Simulator

Connection:
[ Connected ]

Battery:
[ 78% ]

Storage:
[ 5 MB / 16 MB ]

Artificial latency:
[ 300 ms ]

Fail next command:
[ OFF ]

Weather:
[ Rain ]

Device Profile:
[ Keychain V1 Mock ]
```

Developer screen не является пользовательской частью продукта.

Он предназначен для разработки.

---

## Error Simulation

Simulator должен уметь воспроизводить:

```text
connection failure
connection lost
upload failure
storage full
unsupported scene
low battery
timeout
device busy
```

Например:

```text
Fail next upload = true
```

После чего приложение должно пройти реальный error flow.

Это позволит разработать обработку ошибок ещё до появления железа.

---

## Simulated Latency

Device simulator не должен всегда отвечать мгновенно.

Рекомендуется добавить configurable latency:

```text
0 ms
100 ms
300 ms
1000 ms
3000 ms
```

Это позволяет обнаруживать неправильное поведение UI.

Например:

```text
Set Scene
   ↓
loading
   ↓ 500 ms
success
```

---
