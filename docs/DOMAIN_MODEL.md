# Доменная модель

> Абстракция устройства, сцены, возможности экрана и независимость от физического формата.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Device Abstraction

Основным интерфейсом между приложением и устройством является:

```text
DeviceRepository
```

Пример концептуального интерфейса:

```dart
abstract interface class DeviceRepository {
  Stream<List<DeviceInfo>> discoverDevices();

  Future<void> connect(String deviceId);

  Future<void> disconnect();

  Stream<DeviceConnectionState> watchConnectionState();

  Stream<DeviceSnapshot> watchDeviceState();

  Future<void> setScene(String sceneId);

  Future<void> setBrightness(double value);

  Future<void> uploadAsset(
    DeviceAsset asset, {
    void Function(double progress)? onProgress,
  });

  Future<void> deleteAsset(String assetId);

  Future<void> syncTime(DateTime dateTime);
}
```

Интерфейс является доменным.

Он не содержит:

- UUID;
- BLE characteristics;
- MTU;
- BLE packets;
- GATT;
- Android classes;
- iOS classes.

---

## Device Implementations

Будет существовать минимум две реализации.

### Virtual implementation

```text
VirtualDeviceRepository
```

Используется:

- сейчас;
- в unit/integration tests;
- для разработки без железа;
- для демонстраций;
- для UI development;
- для тестирования ошибок.

### Physical implementation

```text
BleDeviceRepository
```

Будет реализована после появления:

- платы;
- BLE-модуля;
- firmware;
- спецификации протокола.

---

## Device Connection State

Соединение моделируется state machine.

```text
idle
 ↓
scanning
 ↓
connecting
 ↓
discovering
 ↓
ready
```

Дополнительные состояния:

```text
disconnecting
disconnected
reconnecting
error
```

Пример:

```dart
enum DeviceConnectionStatus {
  idle,
  scanning,
  connecting,
  discovering,
  ready,
  reconnecting,
  disconnected,
  error,
}
```

UI должен реагировать на состояние, а не самостоятельно определять логику соединения.

---

## Device Snapshot

Текущее состояние устройства представляется одной моделью:

```dart
class DeviceSnapshot {
  final String deviceId;

  final DeviceConnectionStatus connectionStatus;

  final int? batteryPercent;

  final double brightness;

  final String? activeSceneId;

  final String? firmwareVersion;

  final String? protocolVersion;

  final int? storageTotalBytes;

  final int? storageUsedBytes;

  final DeviceCapabilities capabilities;
}
```

В simulator все значения генерируются локально.

В BLE-режиме данные будут получаться от устройства.

---

## Device Capabilities

Нельзя предполагать, что все будущие устройства одинаковы.

Используется:

```dart
class DeviceCapabilities {
  final int displayWidth;
  final int displayHeight;

  final bool supportsAnimation;
  final bool supportsBrightness;
  final bool supportsBatteryLevel;
  final bool supportsCustomImages;
  final bool supportsCustomAnimations;
  final bool supportsTimeSync;

  final int? maxAssetSize;
  final int? maxFps;
}
```

Например:

```text
Keychain V1

displayWidth: 240
displayHeight: 240

animation: true
customImages: true
brightness: true
battery: true
```

Конкретные значения будут определены после появления hardware specification.

---

## Display Profile

Размер и характеристики экрана не должны быть захардкожены по всему приложению.

Вводится:

```text
DisplayProfile
```

Пример:

```dart
class DisplayProfile {
  final int width;
  final int height;

  final DisplayShape shape;

  final double previewAspectRatio;
}
```

Тип:

```dart
enum DisplayShape {
  circle,
}
```

Пока для simulator можно использовать условный профиль:

```text
240 × 240
circle
```

Но:

> 240 × 240 является временным значением для разработки, а не спецификацией устройства.

После получения железа меняется один DeviceProfile, а не весь UI.

---

## Scene Concept

Основной визуальной сущностью приложения является:

```text
Scene
```

Scene — это то, что пользователь хочет видеть на экране устройства.

Примеры:

```text
Normal Eyes
Sleepy Eyes
Happy Eyes
Rain Eyes
Cat
Panda
My Photo
```

---

## Scene Model

Предварительная модель:

```dart
class Scene {
  final String id;

  final String name;

  final SceneType type;

  final SceneSource source;

  final String previewAssetId;

  final bool animated;

  final Set<String> tags;
}
```

---

## Scene Types

```dart
enum SceneType {
  proceduralEyes,
  staticImage,
  frameAnimation,
  animalFace,
}
```

Это позволяет не привязывать всё к одному формату.

---

## Scene Source

```dart
enum SceneSource {
  builtIn,
  userGenerated,
  downloaded,
}
```

`downloaded` понадобится в будущем, если будет серверный каталог.

---

## Important Animation Architecture Decision

Нельзя сейчас выбирать формат физической анимации исходя из удобства Flutter.

Например:

```text
Lottie
Rive
GIF
```

не должны автоматически становиться форматом устройства.

Физическая плата может вообще не уметь их декодировать.

Поэтому разделяются:

```text
Scene Definition
       │
       ▼
Scene Renderer
       │
       ├─────────────► App Preview
       │
       ▼
Device Encoder
       │
       ▼
Device Asset
```

---

## Application Animation vs Device Animation

Приложение может отображать глаза совершенно другим способом, чем устройство.

Например:

```text
Application:

CustomPainter
+
AnimationController
```

а устройство впоследствии:

```text
frame_001
frame_002
frame_003
...
```

или собственный animation format firmware.

Поэтому:

> Scene logic и device encoding — разные подсистемы.

---

## Device Asset

```dart
class DeviceAsset {
  final String id;

  final DeviceAssetType type;

  final Uint8List bytes;

  final int width;

  final int height;

  final int? frameCount;
}
```

На текущем этапе реальная encoding implementation отсутствует.

Для simulator допускается использование PNG.

---
