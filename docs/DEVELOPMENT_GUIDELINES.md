# Правила разработки

> Обязательные архитектурные ограничения и контекст для coding agents.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Source Code Rules for Agents

Следующие правила обязательны для coding agents.

### Rule 1

Presentation layer не импортирует:

```text
flutter_reactive_ble
drift internals
platform-specific libraries
```

---

### Rule 2

Все операции устройства выполняются через:

```text
DeviceRepository
```

---

### Rule 3

Virtual device является first-class implementation.

Нельзя удалять simulator при добавлении BLE.

---

### Rule 4

Нельзя захардкодить:

```text
240x240
```

за пределами DisplayProfile.

---

### Rule 5

UI preview format и physical device format являются разными понятиями.

---

### Rule 6

Нельзя реализовывать BLE-протокол до появления утверждённой protocol specification.

---

### Rule 7

Domain layer не зависит от Flutter plugins.

---

### Rule 8

Image editor не знает о BLE.

---

### Rule 9

AutomationEngine не знает о BLE.

---

### Rule 10

WeatherService не отправляет команды устройству самостоятельно.

Правильно:

```text
Weather
 ↓
AutomationEngine
 ↓
DeviceRepository
```

---

### Rule 11

Infrastructure errors не передаются напрямую в UI.

Они должны преобразовываться в domain failures.

---

### Rule 12

Любая новая device feature сначала должна быть добавлена в:

```text
DeviceCapabilities
```

если её поддержка зависит от модели устройства.

---

### Rule 13

Любая новая implementation устройства должна соответствовать общему DeviceRepository contract.

---

### Rule 14

Бизнес-логика должна тестироваться с VirtualDeviceRepository.

---

### Rule 15

Нельзя добавлять backend только ради convenience.

Backend появляется только при наличии функционального требования.

---

## Agent Context

При работе coding agent должен исходить из следующего:

> Проект является Flutter-приложением для управления круглым BLE-экраном брелока. Физического устройства пока нет. Вся разработка выполняется через Virtual Device Simulator. Любой код должен сохранять возможность позже подключить реальное устройство через BleDeviceRepository без изменения presentation/domain logic.

При неоднозначности архитектурного решения агент должен отдавать предпочтение:

```text
testability
↓
hardware independence
↓
offline operation
↓
simple architecture
↓
future extensibility
```

и избегать преждевременного усложнения.

---
