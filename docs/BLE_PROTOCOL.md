# BLE и протокол устройства

> Будущая BLE-архитектура. Бинарный протокол пока не определён.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

> **Статус протокола: NOT DEFINED.** До получения утверждённой firmware specification нельзя фиксировать UUID, characteristics, MTU, packet layout и правила подтверждения передачи.

## Real BLE Architecture — Future

После появления железа инфраструктура будет выглядеть:

```text
BleDeviceRepository
        │
        ▼
DeviceProtocolClient
        │
        ▼
ProtocolCodec
        │
        ▼
BleTransport
        │
        ▼
flutter_reactive_ble
```

---

## BLE Transport

`BleTransport` отвечает только за:

```text
scan
connect
disconnect
discover services
read characteristic
write characteristic
notifications
```

Он НЕ знает:

```text
what is Scene
what is brightness
what is image
```

---

## Device Protocol Client

Protocol layer знает:

```text
SET_SCENE
SET_BRIGHTNESS
GET_INFO
UPLOAD_ASSET
```

Например:

```text
DeviceRepository.setScene("happy")
          ↓
DeviceProtocolClient
          ↓
ProtocolCodec
          ↓
bytes
```

---

## Protocol Codec

ProtocolCodec будет отвечать за:

```text
domain command
     ↕
binary protocol
```

Например:

```text
SetSceneCommand
 ↓
[0x02, 0x00, 0x17]
```

Формат пока НЕ определяется.

Он будет согласован с firmware team.

---

## Protocol Versioning

Физический протокол обязан иметь version.

Например:

```text
protocolVersion = 1
```

Приложение должно уметь проверять compatibility.

---

## Asset Upload

Domain operation:

```dart
uploadAsset(asset)
```

не зависит от способа передачи.

В simulator:

```text
asset
 ↓
fake transfer
 ↓
VirtualStorage
```

В real BLE:

```text
asset
 ↓
DeviceEncoder
 ↓
chunks
 ↓
BLE
 ↓
device storage
```

---

## Upload State

Общий state:

```dart
sealed class TransferState {}

class TransferIdle extends TransferState {}

class TransferPreparing extends TransferState {}

class TransferRunning extends TransferState {
  final double progress;
}

class TransferCompleted extends TransferState {}

class TransferFailed extends TransferState {}
```

Таким образом UI загрузки можно разработать сейчас.

---
