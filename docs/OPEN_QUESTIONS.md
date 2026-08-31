# Открытые технические вопросы

> Вопросы к hardware и firmware, которые не должны блокировать software-разработку.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Open Technical Questions

Следующие вопросы сознательно остаются открытыми до появления hardware team specification.

### Display

```text
real resolution?
color depth?
refresh rate?
display controller?
```

### Device

```text
MCU?
available RAM?
available flash?
RTC?
accelerometer?
battery monitoring?
```

### Animations

```text
device animation format?
max FPS?
hardware decoding?
compression?
max asset size?
```

### BLE

```text
service UUID?
characteristics?
MTU?
transfer speed?
ACK?
CRC?
authentication?
pairing?
reconnect rules?
```

### Firmware

```text
asset storage model?
scene identifiers?
device capabilities command?
firmware update mechanism?
```

Эти вопросы НЕ должны блокировать разработку Simulator/UI/Application Domain.

---
