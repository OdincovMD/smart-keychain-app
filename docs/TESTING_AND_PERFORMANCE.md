# Тестирование и производительность

> Обязательные уровни тестов и требования к анимациям и обработке изображений.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Testing Strategy

Архитектура должна позволять большую часть приложения тестировать без BLE.

---

### Unit Tests

Обязательно тестируются:

```text
AutomationEngine
ImageProcessor
Crop calculations
Scene selection
Device state transitions
VirtualDeviceEngine
Storage rules
Weather normalization
```

---

### Repository Tests

```text
VirtualDeviceRepository

connect
disconnect
setScene
uploadAsset
storage full
timeout
failure
```

---

### Widget Tests

Критические feature flows:

```text
gallery
scene preview
image editor
device state
transfer progress
```

---

### Integration Tests

Главный сценарий:

```text
Launch App
 ↓
Connect Simulator
 ↓
Open Gallery
 ↓
Select Eyes
 ↓
Set Scene
 ↓
Virtual Screen Changes
 ↓
Import Photo
 ↓
Crop
 ↓
Save
 ↓
Set Photo
 ↓
Virtual Screen Changes
```

Этот integration test должен работать без физического устройства.

---

## Performance Requirements

### Animations

Virtual screen должен стремиться работать с:

```text
60 FPS
```

Тяжёлые операции не должны выполняться каждый frame.

---

### Image Processing

Decode/resize больших фотографий не должен блокировать main UI isolate.

Тяжёлую обработку следует выполнять:

- через image package threaded/isolate API;
- либо через отдельный Dart isolate.

---
