# Local Persistence

> Текущий этап: Appearance + Design Tokens Core. Хранятся стабильные settings,
> выбранная appearance и metadata пользовательских изображений; BLE не входит
> в scope.

## Что хранится в SQLite

Drift управляет таблицами `app_settings` и `user_image_assets`.

### `app_settings`

| Поле | Назначение |
|---|---|
| `id` | стабильный singleton key `app` |
| `active_scene_id` | последний подтверждённый `DeviceSnapshot.activeSceneId`, nullable |
| `brightness_permille` | яркость как canonical integer `0…1000` |
| `appearance` | `obsidian`, `pearl` или `system`; default `system` |
| audit columns | UTC timestamps, revision и служебные delete invariants |

Таблица создаётся в SQLite `STRICT` mode. Диапазон brightness защищён `CHECK`
constraint. Connection при каждом открытии включает `foreign_keys`, WAL,
`synchronous = FULL` и `busy_timeout`.

Connection status, `connecting`, `discovering`, ошибки и другие transient values
не сохраняются. После каждого запуска virtual device начинается в состоянии
`disconnected`.

Built-in scenes также не копируются в SQLite: они поставляются приложением через
`BuiltInSceneRepository`.

Таблица favorites не создавалась: такой feature пока нет в UI или domain, поэтому
отдельная таблица сейчас не имела бы реального владельца и write path.

### `user_image_assets`

| Поле | Назначение |
|---|---|
| `id` | стабильная identity пользовательского asset |
| `original_storage_key` | относительный ключ `user-content/originals/...` |
| `preview_storage_key` | относительный ключ `user-content/previews/...` |
| `crop_center_x/y` | нормализованный центр `0…1` |
| `crop_scale` | масштаб `1…8` |
| `crop_rotation` | rotation `-π…π` |
| audit columns | UTC timestamps, revision и delete invariants |

Таблица также создаётся в `STRICT` mode. `CHECK` constraints защищают controlled
path prefixes и диапазоны `CropSpec`. Изображения не хранятся BLOB-полями.

## Domain boundary

Domain и presentation зависят только от:

```dart
abstract interface class AppSettingsRepository {
  Future<AppSettings> load();
  Future<void> saveActiveSceneId(String sceneId);
  Future<void> saveBrightness(double brightness);
  Future<void> saveAppearance(AppAppearance appearance);
  Future<void> flush();
}
```

Drift tables, generated rows, companions, DAOs и `package:sqlite3` ограничены
директорией `lib/data`. `DriftAppSettingsRepository` преобразует строки БД в
immutable `AppSettings`.

## Startup restoration flow

```text
main
  ↓
bootstrap
  ↓
AppDatabase + DriftAppSettingsRepository
  ↓
load AppSettings
  ├─ restore AppAppearance before runApp
  ↓
validate activeSceneId through SceneRepository
  ├─ known id → restore it
  └─ null/unknown id → Living Eyes fallback
  ↓
VirtualDeviceEngine(initialSceneId, initialBrightness)
  ↓
ProviderScope overrides
  ↓
UI + MaterialApp ThemeMode
```

Повреждённая ссылка на удалённую сцену не приводит к crash. Brightness
восстанавливается отдельно от device connection state. Значение `system`
разрешается в Obsidian или Pearl на Flutter theme boundary, а не в domain.

## Persist-after-command flow

```text
UI intent
  ↓
DeviceController
  ↓
DeviceRepository command completes
  ↓
AppSettingsRepository commits stable preference
```

Persistence находится на application boundary. `DeviceRepository` не знает о
SQLite: будущий physical device сможет иметь собственное состояние яркости, а
приложение — отдельную локальную preference.

Каждая запись settings выполняется одной Drift transaction и завершается только
после commit. На `inactive`/`paused` root lifecycle observer выполняет WAL flush.

## Database ownership

`AppDatabase` создаётся ровно один раз в `bootstrap()` и живёт весь application
lifecycle. Widgets, controllers и providers не открывают новые connections.
Production database расположен в application support directory. In-memory tests
явно закрывают каждый экземпляр после проверки.

## Filesystem boundary

Будущие binary assets не будут храниться в SQLite. Для них определён
`LocalFileStorage`, а production implementation использует application documents
directory и возвращает только относительные controlled paths.

```text
SQLite: identifiers, metadata, relationships, relative paths
Filesystem: original images and generated previews
```

BLOB-данные раздувают базу и ухудшают WAL checkpoint/backup. Absolute paths также
не сохраняются: container path может измениться после restore или reinstall.
Текущие namespace — `user-content/originals/` и `user-content/previews/`.
Production-запись атомарна через временный файл и rename.

## Migration policy

- текущий `schemaVersion = 3`;
- создание новой базы выполняется через `createAll()`;
- upgrades только forward-only;
- downgrade и отсутствующая migration step завершаются явной ошибкой;
- destructive reset или `DROP TABLE` не являются production fallback;
- migration `1 → 2` создаёт `user_image_assets`, не изменяя сохранённые settings;
- migration `2 → 3` добавляет `app_settings.appearance` с безопасным default
  `system`, сохраняя сцену и яркость;
- каждый следующий шаг добавляется отдельно (`2 → 3` и далее) с content-level
  migration test и обновлённым generated schema.

Отсутствующая migration должна остановить release, а не молча удалить данные.

## Image persistence flow

```text
original + preview files → LocalFileStorage
crop/identity metadata   → Drift
Scene                    → UserImageSceneRepository
```

Import публикует metadata последней. Delete сначала переводит активную сцену на
Living Eyes, затем удаляет metadata и файлы с компенсирующим восстановлением при
частичной ошибке. Подробности: [IMAGE_PIPELINE.md](IMAGE_PIPELINE.md).
