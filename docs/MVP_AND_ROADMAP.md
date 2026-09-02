# MVP и план разработки

> Границы версий, порядок реализации и критерии готовности software-прототипа.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Features NOT Included in Initial MVP

Следующие функции сознательно откладываются:

```text
user accounts
cloud sync
online scene store
payments
subscriptions
firmware OTA
BLE security protocol
multiple device sync
social features
sharing marketplace
background weather monitoring
```

Архитектура может учитывать их, но реализация сейчас запрещена без отдельной задачи.

---

## MVP v0.1

Первый полностью работающий software MVP должен работать БЕЗ физического устройства.

---

### MVP v0.1 Features

#### Application

- Flutter application запускается на Android/iOS.
- Работает navigation.
- Работает local persistence.
- Поддерживается Simulator Mode.

#### Virtual Device

- подключение к virtual keychain;
- disconnect;
- connection state;
- fake battery;
- fake brightness;
- fake storage;
- active scene;
- configurable latency.

#### Virtual Screen

- круглый preview;
- поддержка static scene;
- поддержка procedural eyes;
- анимация моргания;
- базовое движение глаз.

#### Content

- built-in scene library;
- выбор scene;
- установка текущей scene;
- favorites.

#### User Images

- выбор изображения;
- crop;
- zoom;
- circular preview;
- сохранение original;
- сохранение CropSpec;
- генерация preview;
- установка изображения на virtual device.

#### Developer Tools

- battery simulation;
- latency simulation;
- disconnect simulation;
- upload failure simulation.

---

## MVP v0.2

После получения первых hardware samples:

```text
BLE discovery
BLE connection
device information
battery
set scene
brightness
basic reconnect
protocol v1
```

---

## MVP v0.3

```text
real asset upload
image encoding
storage management
device capabilities
transfer retry
transfer verification
```

---

## MVP v0.4

```text
automations
time rules
weather
location
background behaviour
```

---

## Future

```text
backend
accounts
cloud scenes
premium packs
OTA firmware
multiple devices
analytics
```

---

## Initial Development Order

Рекомендуемый порядок реализации.

### Phase 1 — Project Foundation

Создать:

```text
Flutter project
Riverpod
go_router
logging
folder structure
app configuration
```

---

### Phase 2 — Domain

Создать основные domain models:

```text
Device
DeviceSnapshot
DeviceCapabilities
DisplayProfile
Scene
SceneType
DeviceRepository
```

---

### Phase 3 — Simulator

Создать:

```text
VirtualDeviceRepository
VirtualDeviceEngine
VirtualDeviceState
```

Поддержать:

```text
connect
disconnect
setScene
brightness
battery
latency
```

---

### Phase 4 — Virtual Screen

Создать:

```text
VirtualScreen
SceneRenderer
StaticImageRenderer
```

---

### Phase 5 — Eye Engine

Статус: **Living Eyes v0.1 реализован для Virtual Device Simulator.**

Реализовано:

```text
ProceduralEyePainter
EyeRuntimeState
EyeEmotion
EyeBehaviourEngine
debug emotion/blink controls
```

---

### Phase 6 — Scene Library

Создать:

```text
built-in scenes
scene metadata
local SceneRepository
favorites
```

---

### Phase 7 — User Images

Создать:

```text
ImagePicker
ImageEditor
CropSpec
ImageProcessor
UserImageRepository
```

---

### Phase 8 — Simulated Upload

Создать:

```text
TransferState
upload progress
failure simulation
VirtualStorage
```

---

### Phase 9 — Automations Foundation

Создать domain layer:

```text
AutomationRule
Trigger
Action
AutomationEngine
```

Без background execution.

---

### Phase 10 — BLE Integration

Начинать только после получения hardware/protocol specification.

---

## Definition of Done for Software Prototype

Первый software prototype считается готовым, если пользователь может:

```text
1. Запустить приложение.

2. Выбрать Demo Keychain.

3. Подключиться к нему.

4. Видеть virtual circular display.

5. Открыть библиотеку глаз.

6. Выбрать animated eyes.

7. Увидеть смену scene на virtual device.

8. Видеть естественное моргание и движение глаз.

9. Выбрать изображение из телефона.

10. Обрезать его под круглый экран.

11. Сохранить результат.

12. Симулировать upload.

13. Установить изображение как active scene.

14. Увидеть его на virtual display.

15. Перезапустить приложение.

16. Увидеть сохранённый пользовательский контент.
```

При выполнении этих пунктов основная software architecture считается проверенной.

---

## Next Architecture Tasks

Следующими отдельными документами должны быть разработаны:

```text
1. DEVICE_SIMULATOR.md

2. DOMAIN_MODEL.md

3. EYE_ANIMATION_ENGINE.md

4. IMAGE_PIPELINE.md

5. FUNCTIONAL_REQUIREMENTS.md

6. BLE_PROTOCOL.md
   после получения информации от firmware team
```

После фиксации этих документов можно переходить к созданию Flutter repository и реализации Phase 1–3.
