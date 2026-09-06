# Система сцен

> Текущий этап: User Content Management. Каталог объединяет встроенные и
> локальные пользовательские сцены; BLE и облачный каталог отсутствуют.

## Scene

`Scene` — доменное описание содержимого, которое пользователь может выбрать для
экрана брелока. Модель содержит:

- стабильный `id`, используемый в `DeviceSnapshot.activeSceneId`;
- `name` и необязательное `description` для каталога;
- типизированный `SceneContent` с preview information;
- `SceneSource`;
- набор `tags`;
- вычисляемые `type` и `animated`.

`type` и `animated` выводятся из контента. В модели нет отдельного asset id для
процедурной сцены и нет дублирующих флагов, которые могли бы противоречить друг
другу.

## SceneType и SceneContent

Сейчас поддерживаются три типа:

| `SceneType` | Контент | Renderer |
|---|---|---|
| `proceduralEyes` | `ProceduralEyesContent(defaultEmotion)` | существующий Living Eyes engine |
| `staticImage` | `StaticImageContent(previewAssetPath)` | Flutter asset preview |
| `userImage` | `UserImageContent(assetId, previewStorageKey)` | controlled local PNG preview |

Конкретный preview asset находится внутри контента, который создаёт repository.
Home screen и gallery не содержат mapping `sceneId → asset/widget`.

## SceneSource

- `builtIn` — сцена поставляется с приложением;
- `userGenerated` — локальный пользовательский asset из image pipeline.

`userGenerated` не означает, что asset уже закодирован или передан на
физическое устройство.

## SceneRepository

Domain-контракт намеренно мал:

```dart
abstract interface class SceneRepository {
  Future<List<Scene>> getAll();
  Future<Scene?> getById(String id);
}
```

Riverpod-провайдер `sceneRepositoryProvider` является DI seam и обязательно
переопределяется в composition root. Presentation читает каталог через
`sceneLibraryProvider`, а отдельную сцену — через `sceneByIdProvider`.

## Repository composition

`BuiltInSceneRepository` владеет:

- перечнем встроенных сцен;
- их стабильными идентификаторами и метаданными;
- путями preview assets;
- соответствующим типизированным контентом.

`UserImageSceneRepository` выводит сцены из сохранённых `UserImageAsset`, не
дублируя scene metadata в отдельной таблице. `CompositeSceneRepository`
объединяет оба источника. Widgets и virtual device зависят только от общего
доменного контракта.

## Scene selection flow

```text
SceneCard(Scene)
  ↓ scene.id
DeviceController.setScene(id)
  ↓
DeviceRepository.setScene(id)
  ↓
VirtualDeviceEngine проверяет id через SceneRepository
  ↓
VirtualDeviceState.activeSceneId
  ↓
DeviceSnapshot.activeSceneId
```

UI не изменяет состояние устройства напрямую и не имеет отдельных веток выбора
для разных сцен.

## Render flow

```text
DeviceSnapshot.activeSceneId
  ↓
sceneByIdProvider / SceneRepository.getById
  ↓
Scene
  ↓
VirtualScreen
  ↓
SceneRenderer (exhaustive switch по SceneContent)
  ├─ ProceduralEyesSceneRenderer
  ├─ StaticImageSceneRenderer
  └─ UserImageSceneRenderer → LocalFileStorage
```

Та же граница `SceneRenderer` используется карточкой каталога с
`animate: false`, поэтому procedural preview остаётся замороженным, а основной
виртуальный экран запускает анимацию.

## User-generated content

Image pipeline сохраняет original и preview в controlled filesystem, metadata —
в Drift. После сохранения провайдер каталога инвалидируется, и новая сцена
появляется в том же selection flow. При удалении активной пользовательской сцены
application service сначала устанавливает безопасную built-in fallback scene.

Crop и локальный preview реализованы. Кодирование для физического дисплея и
бинарный протокол устройства намеренно остаются отдельной будущей системой.
Подробнее: [IMAGE_PIPELINE.md](IMAGE_PIPELINE.md).

`My Content` не является вторым repository. Это пользовательская проекция
общего `sceneLibraryProvider`, отфильтрованная по `SceneSource.userGenerated` и
`UserImageContent`. Только такие сцены получают действия edit/delete. Изменение
crop сохраняет исходный scene id; удаление активной сцены выполняет application
fallback на `BuiltInSceneRepository.livingEyesId` до удаления файлов.
