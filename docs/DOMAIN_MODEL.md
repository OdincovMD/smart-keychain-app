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

  final DisplayProfile displayProfile;

  final String? firmwareVersion;

  final String? protocolVersion;

  final int? storageTotalBytes;

  final int? storageUsedBytes;

  final DeviceCapabilities capabilities;
}
```

`DeviceSnapshot` является единым read model для Home screen. Экран не получает
`DisplayProfile` или capabilities из конкретной реализации устройства: virtual и
будущая BLE-реализация публикуют их через один и тот же repository stream.

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

Текущая модель хранит только стабильную метаинформацию, источник и
типизированный контент:

```dart
class Scene {
  final String id;
  final String name;
  final String? description;
  final SceneContent content;
  final SceneSource source;
  final Set<String> tags;

  SceneType get type => content.type;
  bool get animated => content.animated;
}
```

`type` и `animated` вычисляются из `SceneContent`, а не хранятся второй копией.
Это исключает противоречивые состояния наподобие статичного контента с
`animated == true`.

---

## Scene Content

Сцена содержит типизированный контент, поэтому невозможна комбинация вроде
procedural scene с обязательным фиктивным asset id.

```dart
sealed class SceneContent {}

final class StaticImageContent extends SceneContent {
  final String previewAssetPath;
}

final class ProceduralEyesContent extends SceneContent {
  final EyeEmotion defaultEmotion;
}

final class UserImageContent extends SceneContent {
  final String assetId;
  final String previewStorageKey;
}
```

`StaticImageContent.previewAssetPath` создаёт infrastructure-реализация
`SceneRepository`; Home screen и gallery не знают конкретные asset paths.

Новые форматы добавляются отдельными вариантами `SceneContent` и обрабатываются
exhaustive switch в единственной границе `SceneRenderer`.

Минимальные типы:

```dart
enum SceneType {
  proceduralEyes,
  staticImage,
  userImage,
}
```

---

## Scene Source

```dart
enum SceneSource {
  builtIn,
  userGenerated,
}
```

`userGenerated` используется локальными пользовательскими изображениями.
Передача этого контента на физическое устройство пока не реализована.

---

## Scene Repository

Единственный источник каталога сцен для application- и presentation-слоёв:

```dart
abstract interface class SceneRepository {
  Future<List<Scene>> getAll();
  Future<Scene?> getById(String id);
}
```

`CompositeSceneRepository` объединяет `BuiltInSceneRepository` и
`UserImageSceneRepository`. Композиция внедряется в composition root через
Riverpod. `VirtualDeviceEngine` использует тот же контракт, чтобы принимать
только существующие `sceneId`.

Подробный поток выбора и рендеринга описан в
[SCENE_SYSTEM.md](SCENE_SYSTEM.md).

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

## App Settings

Стабильные локальные preferences представлены Flutter-независимой моделью:

```dart
class AppSettings {
  final String? activeSceneId;
  final double brightness;
}
```

`AppSettingsRepository` является domain boundary над persistence. Текущая
Drift-реализация хранит scene id и brightness, но не хранит connection state.
При startup scene id обязательно проверяется через `SceneRepository`; неизвестное
значение заменяется default built-in scene.

Подробности схемы, lifecycle и migrations описаны в
[PERSISTENCE.md](PERSISTENCE.md).

---

## User Image Asset

Локальное изображение пользователя представлено Flutter-независимой моделью:

```dart
class UserImageAsset {
  final String id;
  final String originalStorageKey;
  final String previewStorageKey;
  final CropSpec cropSpec;
  final DateTime createdAt;
}
```

`CropSpec` хранит нормализованный центр `0…1`, масштаб и rotation. Модель не
содержит `File`, `XFile`, `ImageProvider` или абсолютные пути. Metadata живёт в
Drift, original и подготовленный PNG preview — в `LocalFileStorage`.

Полный lifecycle описан в [IMAGE_PIPELINE.md](IMAGE_PIPELINE.md).

---
