# Контент и обработка изображений

> Локальная библиотека, импорт, crop, форматы, persistence и файловое хранение.

> Источник: исходная спецификация версии 0.1 (Draft / Initial Architecture).

## Content Library

Приложение должно иметь локальную библиотеку сцен.

Категории могут включать:

```text
Eyes
Animals
Emotions
Seasonal
My Content
Favorites
```

Категории являются логической системой.

Конкретный UI определяется позже.

---

## Built-in Content

Built-in content поставляется вместе с приложением.

Например:

```text
assets/
  scenes/
    eyes/
    animals/
```

Metadata сцен желательно хранить отдельно.

Пример:

```json
{
  "id": "eyes_sleepy_v1",
  "name": "Sleepy",
  "type": "proceduralEyes",
  "animated": true,
  "tags": [
    "eyes",
    "sleep"
  ]
}
```

---

## User Image Workflow

Основной pipeline:

```text
Select Image
      ↓
Load Original
      ↓
Image Editor
      ↓
Crop Parameters
      ↓
Preview
      ↓
Processed Preview
      ↓
Save Metadata
      ↓
Set Scene
```

---

## Original Image Preservation

Оригинальное изображение нельзя уничтожать после crop.

Хранить необходимо:

```text
original image
+
crop specification
+
generated preview
```

Например:

```dart
class UserImage {
  final String id;

  final String originalFilePath;

  final CropSpec crop;

  final String previewFilePath;
}
```

---

## Crop Specification

Пример:

```dart
class CropSpec {
  final double centerX;
  final double centerY;

  final double scale;

  final double rotation;
}
```

Важно хранить координаты в нормализованном виде:

```text
0.0 ... 1.0
```

а не:

```text
137 pixels
```

Тогда crop можно повторно применить для другого разрешения экрана.

---

## Image Processing Pipeline

Создаётся отдельный:

```text
ImageProcessor
```

Он отвечает за:

```text
decode
crop
rotate
resize
mask
compress
encode
```

Пример pipeline:

```text
Original JPEG
     ↓
Decode
     ↓
Crop
     ↓
Resize
     ↓
Preview image
```

Позже:

```text
Preview source
     ↓
DeviceEncoder
     ↓
RGB565 / JPEG / PNG / custom
```

---

## UI Image Format != Device Image Format

Это обязательное правило.

Application preview может использовать:

```text
PNG
```

Физическое устройство может потребовать:

```text
RGB565
```

или другой формат.

Поэтому преобразование на устройство выполняет:

```text
DeviceAssetEncoder
```

а не Image Editor.

---

## Application Persistence

Приложение должно работать offline-first.

Без сети должны работать:

- встроенные scenes;
- пользовательские изображения;
- simulator;
- device control;
- gallery;
- настройки;
- локальные автоматизации, не требующие внешней информации.

---

## Local Database

Для структурированных данных используется:

```text
Drift / SQLite
```

Предварительные таблицы:

```text
scenes
user_assets
favorite_scenes
devices
automations
app_settings
```

---

## File Storage

Большие binary assets НЕ следует хранить непосредственно в SQLite.

Используется:

```text
Application Documents Directory
```

SQLite хранит:

```text
asset id
metadata
file path
```

Файл хранит:

```text
PNG
JPEG
animation
original photo
```

---

## Secure Storage

Для чувствительных данных:

```text
flutter_secure_storage
```

В перспективе там могут храниться:

- device ownership token;
- refresh token аккаунта;
- cryptographic keys;
- pairing data.

Не использовать SharedPreferences для секретов.

---
