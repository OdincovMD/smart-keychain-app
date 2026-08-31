# Архитектура

> Слои, зависимости, конфигурация, хранение состояния и ключевые системные ограничения.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Основной архитектурный принцип

Приложение не должно зависеть от конкретной реализации Bluetooth, прошивки или физического устройства.

Основная логика должна работать одинаково с:

1. виртуальным устройством;
2. настоящим BLE-устройством.

```text
                        Application
                            │
                            ▼
                     DeviceRepository
                            │
               ┌────────────┴────────────┐
               │                         │
               ▼                         ▼
      VirtualDeviceRepository     BleDeviceRepository
               │                         │
               ▼                         ▼
       Device Simulator            BLE / Firmware
```

UI не должен знать, какое устройство используется.

Например команда:

```dart
deviceRepository.setScene(sceneId);
```

должна одинаково работать:

```text
Simulator Mode
      ↓
Virtual screen changes
```

и:

```text
Real Device Mode
      ↓
BLE command
      ↓
Physical screen changes
```

Это является одним из основных архитектурных требований проекта.

---

## Technology Stack

### Основной стек

Начальная технологическая база:

| Назначение | Технология |
|---|---|
| Mobile framework | Flutter 3.47+ |
| Language | Dart 3.13+ |
| Platforms | Android / iOS |
| State management | Riverpod 3.x |
| Navigation | go_router |
| Local structured database | Drift / SQLite |
| Secure key/value storage | flutter_secure_storage |
| Image selection | image_picker |
| Image crop UI | crop_your_image |
| Image processing | image |
| BLE | flutter_reactive_ble |
| Background tasks | workmanager — при необходимости |
| Unit tests | flutter_test |
| Integration tests | integration_test |

Версии зависимостей должны фиксироваться в `pubspec.lock`.

Архитектура не должна зависеть от особенностей конкретной minor/patch версии библиотеки.

---

## Why Flutter

Flutter выбран как основной mobile framework по следующим причинам:

- единая кодовая база Android/iOS;
- возможность использования нативных Android/iOS API;
- хорошая поддержка BLE;
- удобная работа с CustomPainter;
- высокая производительность анимаций;
- удобная реализация виртуального экрана;
- встроенная система анимаций;
- удобная обработка gesture input;
- hot reload;
- возможность при необходимости написать Swift/Kotlin platform adapter.

Платформенно-зависимый код допускается, но должен быть изолирован.

```text
Flutter Domain/Application
           │
           ▼
Platform Adapter
      ┌────┴────┐
      ▼         ▼
    Swift     Kotlin
```

---

## BLE Technology

Предпочтительная BLE-библиотека для первой реализации:

```text
flutter_reactive_ble
```

Причины:

- Android/iOS;
- BLE Central;
- permissive BSD license;
- отсутствие необходимости связывать остальное приложение с конкретной BLE-библиотекой.

При этом:

> Код `flutter_reactive_ble` НЕ должен использоваться вне infrastructure/device слоя.

Запрещено:

```dart
// UI layer

FlutterReactiveBle().connectToDevice(...)
```

Допустимо:

```text
UI
 ↓
Controller
 ↓
DeviceRepository
 ↓
BleDeviceRepository
 ↓
BleTransport
 ↓
flutter_reactive_ble
```

Таким образом BLE-библиотека может быть заменена без изменения приложения.

---

## Architectural Layers

Используется упрощённая Clean Architecture / layered architecture.

```text
┌───────────────────────────────┐
│         PRESENTATION          │
│                               │
│ Screens                       │
│ Widgets                       │
│ Controllers                   │
│ Riverpod Providers            │
└──────────────┬────────────────┘
               │
               ▼
┌───────────────────────────────┐
│          APPLICATION          │
│                               │
│ Use cases                     │
│ Coordinators                  │
│ Automation Engine             │
│ Application Services          │
└──────────────┬────────────────┘
               │
               ▼
┌───────────────────────────────┐
│            DOMAIN             │
│                               │
│ Entities                      │
│ Value Objects                 │
│ Repository interfaces         │
│ Device Commands               │
│ Business Rules                │
└──────────────┬────────────────┘
               │
               ▼
┌───────────────────────────────┐
│       INFRASTRUCTURE          │
│                               │
│ BLE                           │
│ Database                      │
│ File System                   │
│ Weather API                   │
│ Location API                  │
│ Simulator                     │
└───────────────────────────────┘
```

---

## Project Structure

Предварительная структура проекта:

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── bootstrap.dart
│   └── app_config.dart
│
├── core/
│   ├── errors/
│   ├── logging/
│   ├── utils/
│   ├── storage/
│   └── types/
│
├── domain/
│   │
│   ├── device/
│   │   ├── device.dart
│   │   ├── device_state.dart
│   │   ├── device_capabilities.dart
│   │   ├── device_command.dart
│   │   └── device_repository.dart
│   │
│   ├── content/
│   │   ├── scene.dart
│   │   ├── scene_type.dart
│   │   ├── asset.dart
│   │   └── animation.dart
│   │
│   ├── image/
│   │   ├── user_image.dart
│   │   └── crop_spec.dart
│   │
│   └── automation/
│       ├── automation_rule.dart
│       ├── automation_trigger.dart
│       └── automation_action.dart
│
├── infrastructure/
│   │
│   ├── device/
│   │   ├── simulator/
│   │   └── ble/
│   │
│   ├── database/
│   ├── filesystem/
│   ├── weather/
│   └── location/
│
├── features/
│   │
│   ├── home/
│   ├── devices/
│   ├── gallery/
│   ├── scene_preview/
│   ├── image_import/
│   ├── image_editor/
│   ├── automations/
│   ├── settings/
│   └── developer/
│
├── services/
│   ├── image_processor/
│   ├── scene_renderer/
│   └── automation_engine/
│
└── main.dart
```

Структура может уточняться по мере развития проекта.

Главное правило:

> features не должны напрямую зависеть от BLE, базы данных или Weather API.

---

## Device Mode

В конфигурации приложения вводится:

```dart
enum DeviceMode {
  simulator,
  bluetooth,
}
```

Но UI не должен проверять:

```dart
if (deviceMode == bluetooth) {
   ...
}
```

Вместо этого dependency injection выбирает implementation:

```text
DeviceRepository

Simulator:
VirtualDeviceRepository

Production:
BleDeviceRepository
```

---

## Dependency Injection

Riverpod используется одновременно для:

- state management;
- dependency injection.

Например:

```dart
final deviceRepositoryProvider =
    Provider<DeviceRepository>((ref) {
  return VirtualDeviceRepository();
});
```

Позже:

```dart
return BleDeviceRepository(...);
```

UI при этом не изменяется.

---

## Application State

Не создавать один огромный глобальный:

```text
AppState
```

Использовать отдельные feature states:

```text
DeviceState
GalleryState
ImageEditorState
AutomationState
SettingsState
```

---

## Error Model

Ошибки infrastructure должны переводиться в domain errors.

Например BLE exception:

```text
GattError 133
```

не должен попадать напрямую в UI.

Вводятся:

```dart
sealed class DeviceFailure {}

class ConnectionFailure extends DeviceFailure {}

class DeviceUnavailableFailure extends DeviceFailure {}

class DeviceTimeoutFailure extends DeviceFailure {}

class StorageFullFailure extends DeviceFailure {}

class TransferFailure extends DeviceFailure {}

class UnsupportedFeatureFailure extends DeviceFailure {}
```

---

## Logging

В проекте должен существовать централизованный logging abstraction.

Минимальные категории:

```text
APP
DEVICE
BLE
SIMULATOR
IMAGE
AUTOMATION
DATABASE
WEATHER
```

Пример:

```text
[DEVICE] Setting scene sleepy-eyes
[SIMULATOR] Scene changed successfully
```

Позже:

```text
[BLE] WRITE command SET_SCENE
```

В production запрещено логировать:

- secret tokens;
- exact sensitive coordinates;
- cryptographic keys.

---

## Backend Strategy

Backend отсутствует в MVP.

Архитектура:

```text
Mobile App
   │
   ├── local database
   ├── local files
   ├── external weather API
   └── device
```

Это позволяет:

- быстрее начать;
- уменьшить infrastructure complexity;
- работать offline;
- не создавать аккаунты раньше времени.

---

## Future Backend

Backend может появиться для:

```text
accounts
cloud synchronization
scene catalog
premium content
purchases
device registry
analytics
remote configuration
firmware catalog
```

Архитектура приложения должна позволять добавить:

```text
RemoteSceneRepository
```

рядом с:

```text
LocalSceneRepository
```

---

## Offline-first Requirement

Приложение должно запускаться без интернет-соединения.

Без интернета пользователь должен иметь возможность:

```text
connect device
change scene
use gallery
use custom images
change brightness
use local automations
```

Weather functionality может быть временно недоступна.

---

## Privacy Principle

Приложение должно собирать минимально необходимое количество данных.

Например для Weather Automation:

```text
Phone Location
      ↓
Weather Service
      ↓
Weather Condition
      ↓
Automation
      ↓
Device
```

Device не должен получать координаты.

---

## Architectural Goal

Главная цель первой архитектуры:

> создать полноценное мобильное приложение, способное работать с виртуальным брелоком сегодня и с физическим BLE-брелоком завтра без переписывания основной бизнес-логики.

Целевая схема:

```text
                         ┌─────────────┐
                         │   Weather   │
                         └──────┬──────┘
                                │
                                ▼
┌────────────┐          ┌──────────────┐
│   Gallery  │─────────►│ Application  │
└────────────┘          │    Logic     │
                        └──────┬───────┘
┌────────────┐                 │
│Image Editor│─────────────────┤
└────────────┘                 │
                               ▼
                     ┌──────────────────┐
                     │ DeviceRepository │
                     └────────┬─────────┘
                              │
                  ┌───────────┴───────────┐
                  │                       │
                  ▼                       ▼
         ┌─────────────────┐       ┌─────────────┐
         │ Virtual Device  │       │ BLE Device  │
         │    Simulator    │       │   Adapter   │
         └────────┬────────┘       └──────┬──────┘
                  │                       │
                  ▼                       ▼
         Virtual Circular             Physical
              Display                  Keychain
```

---
