# Функциональные требования

> Функциональные области и ответственность пользовательских и developer-экранов.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Functional Areas

Полная система приложения предварительно делится на:

```text
Device Management
Scene Library
Scene Preview
Eye Animation
Custom Images
Automations
Settings
Developer Simulator
```

Позже:

```text
Accounts
Cloud Content
Store
Firmware Update
Analytics
```

---

## Screen Functional Specification

В данном документе не определяется визуальный дизайн экранов.

Определяется только функциональность.

---

## Bootstrap / Splash

Назначение:

- инициализация приложения;
- открытие database;
- загрузка settings;
- определение device mode;
- восстановление предыдущей сессии;
- загрузка локальной content library.

Не должен содержать сложной бизнес-логики.

---

## Onboarding

Функции:

- краткое объяснение приложения;
- выбор/подключение устройства;
- permissions по мере необходимости;
- возможность продолжить в Simulator Mode.

Пользователь без физического устройства должен иметь возможность использовать приложение.

---

## Device Discovery Screen

В будущем:

- BLE scan;
- список найденных устройств;
- connection;
- pairing/binding.

Сейчас:

- список virtual devices;
- Demo Device;
- подключение к simulator.

---

## Home / Device Screen

Основная функциональность:

- текущее устройство;
- connection status;
- active scene;
- virtual/real display preview;
- battery;
- brightness;
- storage;
- быстрый переход к смене scene.

---

## Gallery Screen

Функции:

- список scenes;
- категории;
- фильтрация;
- favorites;
- пользовательский контент;
- preview;
- выбор scene.

---

## Scene Details / Preview

Функции:

- fullscreen preview;
- запуск animation;
- информация о scene;
- Set as Current;
- Favorite;
- совместимость с устройством.

---

## Image Import

Функции:

- выбор изображения из gallery;
- в будущем камера;
- передача изображения в editor.

---

## Image Editor

Функции:

- move;
- zoom;
- crop;
- rotate;
- circular preview;
- reset;
- save.

Image Editor не занимается BLE.

---

## My Content

Функции:

- пользовательские изображения;
- пользовательские scenes;
- rename;
- delete;
- edit crop;
- set current.

---

## Automations Screen

Автоматизации являются отдельной подсистемой.

Пользователь задаёт:

```text
TRIGGER
   ↓
ACTION
```

Например:

```text
Weather = Rain
   ↓
Scene = Rain Eyes
```

или:

```text
Time = 23:00
   ↓
Scene = Sleepy
```

---

## Settings

Settings могут включать:

```text
device
brightness
simulator
animations
developer options
notifications
privacy
```

В будущем:

```text
account
cloud
firmware
```

---

## Developer Screen

Developer screen включается только debug build или специальным developer flag.

Функции:

```text
Device Mode:
    Simulator
    Real BLE

Simulator Profile

Battery

Storage

Artificial Latency

Connection State

Trigger Error

Weather Override

Clear Local Database

Show Debug Logs
```

---
