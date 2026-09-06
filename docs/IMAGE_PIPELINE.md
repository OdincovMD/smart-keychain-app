# Image Pipeline Core

> Текущий этап: локальный импорт пользовательского изображения. BLE, device
> encoding, облако и синхронизация не входят в реализацию.

## Архитектурная граница

Платформенный picker, файловая система и Drift изолированы за доменными
контрактами. UI не получает абсолютные пути и не вызывает platform API напрямую.

```text
DeviceHomeScreen
  ↓ intent
UserImageController
  ↓
UserImageWorkflow
  ├─ ImagePickerGateway ── PlatformImagePickerGateway ── image_picker
  ├─ ImageProcessor ────── IsolatedImageProcessor
  ├─ LocalFileStorage ──── ApplicationDocumentsFileStorage
  └─ UserImageAssetRepository ── DriftUserImageAssetRepository
                                      ↓
                              user_image_assets
```

`image_picker` используется только в infrastructure boundary. Полученный файл
немедленно читается и копируется в controlled storage приложения; временный URI
picker никогда не становится идентичностью контента.

Плагин и pure-Dart `image` имеют permissive BSD/MIT-compatible licences и
закрыты интерфейсами `ImagePickerGateway`/`ImageProcessor`. Federated
`image_picker` транзитивно включает `http` через `cross_file`, но production-код
его не импортирует, URL не принимает, а release Android manifest не объявляет
`INTERNET`. Это инертный transitive package, а не сетевой product path.

## Доменная модель

`UserImageAsset` хранит:

- стабильный `id`;
- относительные `originalStorageKey` и `previewStorageKey`;
- нормализованный `CropSpec`;
- UTC-время создания.

`CropSpec.centerX/centerY` находятся в диапазоне `0…1`, `scale` — `1…8`,
`rotation` — `-π…π`. Благодаря нормализованным координатам сохранённый crop не
зависит от размеров телефона или виджета редактора.

## Controlled storage

Разрешены только два namespace:

```text
user-content/originals/<asset-id>.<source-extension>
user-content/previews/<asset-id>.png
```

В SQLite сохраняются эти относительные ключи, но не абсолютный sandbox path.
Production storage проверяет ключи, пишет через временный `.part` и атомарный
rename. Оригинал сохраняется без перекодирования; preview всегда является
подготовленным PNG.

## Processing

`IsolatedImageProcessor` выполняет тяжёлую работу через `Isolate.run`, не на UI
isolate:

1. декодирует поддерживаемый raster format;
2. применяет orientation metadata;
3. применяет rotation и нормализованный crop;
4. масштабирует результат под `DisplayProfile`;
5. обрезает alpha за пределами круглого экрана;
6. кодирует preview в PNG.

Размер результата берётся из `DisplayProfile`, а не захардкожен в editor или
workflow. Это preview/simulator representation, не будущий формат firmware.

## Import transaction order

```text
pick
  ↓ validate
copy original
  ↓ editor returns CropSpec
process preview
  ↓ write preview
persist UserImageAsset metadata LAST
  ↓ invalidate scene providers
user scene appears in CompositeSceneRepository
```

Metadata публикуется последней, поэтому каталог не видит незавершённый asset.
При ошибке processing, записи preview или persistence workflow удаляет уже
созданные файлы. Отмена picker является обычным результатом, а не ошибкой.

## Edit и delete

`UserImageWorkflow.updateCrop()` повторно читает неизменённый original,
генерирует preview и обновляет metadata. Если persistence не удалась, старый
preview восстанавливается.

`DeleteUserImageScene`:

1. если сцена активна, переключает устройство и settings на Living Eyes;
2. читает файлы для возможного rollback;
3. удаляет metadata;
4. удаляет original и preview;
5. при частичной файловой ошибке восстанавливает asset.

После успешного удаления `UserImageSceneRepository` больше не возвращает сцену.

## User Content Lifecycle

### Create

`DeviceHomeScreen` запускает существующий import flow. После выбора файла
`UserImageWorkflow` копирует original в controlled storage, editor возвращает
нормализованный `CropSpec`, preview и metadata сохраняются в безопасном порядке.
Новая пользовательская сцена появляется в общем `SceneRepository`; отдельного
presentation-каталога изображений нет.

### View и select

Экран `My Content` является отфильтрованной проекцией `sceneLibraryProvider` и
показывает только `SceneSource.userGenerated` с `UserImageContent`. Действие
«На экран» проходит через `DeviceController` и общий `DeviceRepository`, поэтому
виртуальный экран реагирует тем же способом, что и на встроенную сцену.

### Edit

```text
user Scene
  ↓ assetId
UserImageWorkflow.loadForEdit()
  ↓ original bytes + persisted CropSpec
ImageEditorScreen
  ↓ updated CropSpec
UserImageWorkflow.updateCrop()
  ↓ replace preview + persist metadata
same asset id → same scene id
```

Редактор восстанавливает `centerX`, `centerY`, `scale` и `rotation`. Обычное
редактирование не создаёт новый asset. Metadata публикуется только после
успешной генерации preview; если её сохранение не удалось, старый preview
восстанавливается и предыдущая корректная сцена остаётся доступной.

### Delete

Удаление доступно только на `My Content` и требует подтверждения. UI передаёт
стабильный scene id в `DeleteUserImageScene`; application operation выполняет
fallback активной сцены на Living Eyes, удаляет metadata, original и preview и
пытается восстановить asset при частичной файловой ошибке. После успеха
репозиторные Riverpod-проекции инвалидируются, и сцена исчезает из обоих
каталогов.

После edit/delete данные проверяются повторным созданием repository graph над
тем же persistent store: controller state не считается durable state.

## Rendering

`CompositeSceneRepository` объединяет built-in и user-generated источники.
Пользовательская сцена содержит `UserImageContent(assetId,
previewStorageKey)`. Единственная новая ветка `SceneRenderer` читает preview
через `LocalFileStorage`; widget не открывает файл по абсолютному пути.

Отсутствующий или повреждённый preview отображается безопасным placeholder и не
ломает встроенный каталог.

## Ошибки

Ожидаемые ошибки являются значениями `Result<T, UserImageFailure>`:

- неподдерживаемый или повреждённый файл;
- ошибка чтения;
- ошибка обработки;
- ошибка controlled storage;
- ошибка persistence;
- невозможность безопасно сменить активную сцену перед удалением.

Infrastructure логирует исходную ошибку и stack trace до преобразования в
типизированный failure. Локализованный текст выбирает presentation layer.

## Будущая граница физического устройства

```text
original + CropSpec
  ├─ current: ImageProcessor → local PNG preview → VirtualScreen
  └─ future:  + DeviceCapabilities
                 ↓
              DeviceAssetEncoder → physical binary → DeviceRepository upload
```

`DeviceImageEncoder` намеренно отсутствует: формат пикселей, compression и BLE
transport должны определяться только после спецификации display/firmware.
