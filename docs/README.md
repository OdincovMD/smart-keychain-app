# Документация Smart Keychain App

> Версия документации: 0.1<br>
> Статус: Draft / Initial Architecture<br>
> Платформы: Android и iOS<br>
> Framework: Flutter<br>
> Подход: offline-first, modular, hardware-independent<br>
> Backend для MVP: не требуется<br>
> Текущее устройство разработки: Virtual Device Simulator

## Что это за проект

Smart Keychain App — мобильное приложение-компаньон для физического брелока или игрушки с круглым цветным экраном. Пользователь сможет подключить устройство, выбрать визуальную сцену, настроить яркость, загрузить собственную фотографию и увидеть результат на экране брелока. Основной характер продукта создают «живые» процедурно анимированные глаза и эмоциональные состояния.

Сейчас физического устройства нет. Проект сознательно начинается с виртуального брелока, который имитирует подключение, экран, батарею, хранилище, задержки и ошибки. Симулятор — постоянная реализация общего контракта устройства, а не временный mock. Позже рядом с ним появится BLE-адаптер без переписывания presentation- и domain-слоёв.

## Карта документации

| Документ | Что в нём находится |
|---|---|
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | Назначение продукта и стратегия разработки без физического устройства |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Слои, зависимости, стек, DI, ошибки, logging, offline-first и backend strategy |
| [DOMAIN_MODEL.md](DOMAIN_MODEL.md) | `DeviceRepository`, состояние и возможности устройства, `DisplayProfile`, сцены и device assets |
| [DEVICE_SIMULATOR.md](DEVICE_SIMULATOR.md) | Устройство симулятора, virtual screen, latency и моделирование ошибок |
| [EYE_ANIMATION_ENGINE.md](EYE_ANIMATION_ENGINE.md) | Процедурный renderer глаз, эмоции и runtime-поведение |
| [SCENE_SYSTEM.md](SCENE_SYSTEM.md) | Домен сцен, repository, выбор сцены и data-driven rendering |
| [PERSISTENCE.md](PERSISTENCE.md) | Drift schema, settings restoration, filesystem boundary и migrations |
| [IMAGE_PIPELINE.md](IMAGE_PIPELINE.md) | Реализованный импорт, crop, processing, controlled storage и user-generated scenes |
| [CONTENT_AND_IMAGE_PIPELINE.md](CONTENT_AND_IMAGE_PIPELINE.md) | Библиотека сцен, изображения пользователя, crop, форматы и локальное хранение |
| [FUNCTIONAL_REQUIREMENTS.md](FUNCTIONAL_REQUIREMENTS.md) | Экраны приложения и их функциональная ответственность |
| [AUTOMATIONS.md](AUTOMATIONS.md) | Правила автоматизаций, триггеры, действия, погода и background-ограничения |
| [BLE_PROTOCOL.md](BLE_PROTOCOL.md) | Границы BLE-слоёв и будущего бинарного протокола; реальные параметры пока не определены |
| [MVP_AND_ROADMAP.md](MVP_AND_ROADMAP.md) | Scope версий, порядок разработки и Definition of Done |
| [TESTING_AND_PERFORMANCE.md](TESTING_AND_PERFORMANCE.md) | Unit/widget/integration tests и требования к производительности |
| [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) | Обязательные правила для разработчиков и coding agents |
| [ARCHITECTURAL_DECISIONS.md](ARCHITECTURAL_DECISIONS.md) | Реестр уже принятых архитектурных решений |
| [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) | Вопросы к display, hardware, BLE и firmware |

## Рекомендуемый порядок чтения

1. [Обзор проекта](PROJECT_OVERVIEW.md).
2. [Архитектура](ARCHITECTURE.md).
3. [Доменная модель](DOMAIN_MODEL.md).
4. [Virtual Device Simulator](DEVICE_SIMULATOR.md).
5. [MVP и план разработки](MVP_AND_ROADMAP.md).
6. Остальные тематические спецификации — перед работой над соответствующей подсистемой.

## Зафиксированная граница текущего этапа

До появления hardware- и firmware-спецификаций нельзя придумывать реальные UUID, characteristics, MTU, бинарный формат команд или формат device assets. Эти пробелы не блокируют разработку домена, UI, симулятора, локального контента и тестов.
