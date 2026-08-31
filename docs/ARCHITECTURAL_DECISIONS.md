# Архитектурные решения

> Реестр принятых решений уровня ADR.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Current Architectural Decisions

Зафиксированные решения:

```text
ADR-001
Mobile framework = Flutter

ADR-002
Android + iOS share one application codebase

ADR-003
Application is offline-first

ADR-004
Backend is not required for MVP

ADR-005
Device access is abstracted through DeviceRepository

ADR-006
Virtual Device Simulator is a permanent project component

ADR-007
BLE implementation is isolated in infrastructure layer

ADR-008
flutter_reactive_ble is the initial BLE candidate

ADR-009
Riverpod is used for state management and dependency injection

ADR-010
Drift/SQLite is used for structured local persistence

ADR-011
Original user images are preserved

ADR-012
Crop settings are stored independently from generated images

ADR-013
Application scene representation is independent from physical device encoding

ADR-014
Eye animations initially use a procedural rendering approach

ADR-015
Device display characteristics are defined through DisplayProfile/DeviceCapabilities

ADR-016
Real BLE protocol is intentionally undefined until firmware specification exists
```

---
