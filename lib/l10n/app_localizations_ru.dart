// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Умный брелок';

  @override
  String get discoveryEyebrow => 'ВИРТУАЛЬНАЯ МАСТЕРСКАЯ';

  @override
  String get discoveryTitle => 'Выберите брелок';

  @override
  String get discoverySubtitle =>
      'Подключите демо-устройство и попробуйте сцены без настоящего брелока.';

  @override
  String get demoKeychain => 'Demo Keychain';

  @override
  String get demoMode => 'ДЕМО-РЕЖИМ';

  @override
  String batteryPercent(int value) {
    return 'Заряд $value%';
  }

  @override
  String get connect => 'Подключить';

  @override
  String get connecting => 'Подключаем…';

  @override
  String get discovering => 'Настраиваем экран…';

  @override
  String get connected => 'Подключено';

  @override
  String get online => 'На связи';

  @override
  String get disconnected => 'Отключено';

  @override
  String get disconnecting => 'Отключаем…';

  @override
  String get disconnect => 'Отключить';

  @override
  String get deviceHomeEyebrow => 'My Keychain';

  @override
  String get companionName => 'Luna';

  @override
  String get companionWelcome => 'good\nto see you';

  @override
  String get heartSymbolLabel => 'сердце';

  @override
  String get deviceReady => 'Готов к командам';

  @override
  String get sceneLibrary => 'Настроение экрана';

  @override
  String get sceneLibrarySubtitle =>
      'Выберите образ, который появится на брелоке.';

  @override
  String get wardrobe => 'Гардероб';

  @override
  String get allLooks => 'Все';

  @override
  String get allLooksTitle => 'Все образы';

  @override
  String get moodNeutral => 'Настроение: игривое';

  @override
  String get presenceNeutral => 'Всегда рядом с тобой';

  @override
  String get changeLook => 'Сменить образ';

  @override
  String get tryingOn => 'Примеряем…';

  @override
  String get activeScene => 'НА ЭКРАНЕ';

  @override
  String get installScene => 'Установить';

  @override
  String get installed => 'Установлено';

  @override
  String get installing => 'Отправляем…';

  @override
  String get brightness => 'Яркость';

  @override
  String get brightnessHint => 'Команда отправится после отпускания ползунка.';

  @override
  String get simulatorSettings => 'Настройки симулятора';

  @override
  String get simulatorSettingsHint =>
      'Проверьте задержку команд и поведение живого экрана.';

  @override
  String get appearance => 'Оформление';

  @override
  String get appearanceHint =>
      'Одна система Chrome Kiss в тёмной или светлой подаче.';

  @override
  String get appearanceObsidian => 'Obsidian';

  @override
  String get appearancePearl => 'Pearl';

  @override
  String get appearanceSystem => 'Как в системе';

  @override
  String get latency => 'Задержка';

  @override
  String latencyValue(int value) {
    return '$value мс';
  }

  @override
  String get close => 'Закрыть';

  @override
  String get sceneLivingEyes => 'Живой взгляд';

  @override
  String get sceneLivingEyesDescription =>
      'Сам моргает, наблюдает и меняет настроение.';

  @override
  String get sceneMintEyes => 'Мятный взгляд';

  @override
  String get sceneMintEyesDescription => 'Спокойные глаза с тёплой искрой.';

  @override
  String get sceneSunnyFriend => 'Солнечный друг';

  @override
  String get sceneSunnyFriendDescription =>
      'Коралловое настроение на весь день.';

  @override
  String get connectionError => 'Не удалось выполнить команду устройства.';

  @override
  String get retry => 'Попробовать снова';

  @override
  String get pairingTitle => 'Найди свой брелок';

  @override
  String get pairingIntro => 'Он рядом — осталось только познакомиться.';

  @override
  String get pairingFindAction => 'Найти брелок';

  @override
  String get pairingSearchingTitle => 'Ищем рядом…';

  @override
  String get pairingSearchingBody =>
      'Поднеси брелок ближе. Это займёт всего мгновение.';

  @override
  String get pairingFoundTitle => 'Нашли тебя';

  @override
  String get pairingFoundBody => 'Виртуальный брелок готов познакомиться.';

  @override
  String get pairingConnectingTitle => 'Подключаем…';

  @override
  String get pairingConnectingBody => 'Ещё мгновение — и он проснётся.';

  @override
  String get pairingConnectedTitle => 'Вы на связи';

  @override
  String get pairingConnectedBody => 'Привет. Твой брелок уже просыпается.';

  @override
  String get pairingConnectedAction => 'Мы на связи';

  @override
  String get pairingErrorTitle => 'Не получилось подключиться';

  @override
  String get pairingErrorBody =>
      'Попробуй ещё раз. Твои образы и настройки останутся на месте.';

  @override
  String get pairingVirtualKeychain => 'Виртуальный брелок';

  @override
  String get pairingDemoMarker => 'ДЕМО';

  @override
  String get pairingDemoHint => 'Демо-брелок для знакомства с приложением';

  @override
  String get pairingStageDormantLabel => 'Виртуальный брелок спит';

  @override
  String get pairingStageSearchingLabel => 'Ищем виртуальный брелок рядом';

  @override
  String get pairingStageFoundLabel => 'Виртуальный брелок найден';

  @override
  String get pairingStageConnectingLabel => 'Виртуальный брелок подключается';

  @override
  String get pairingStageConnectedLabel => 'Виртуальный брелок подключён';

  @override
  String get pairingStageErrorLabel =>
      'Не удалось подключить виртуальный брелок';

  @override
  String get devicePreviewLabel => 'Виртуальный экран брелока';

  @override
  String get openSimulatorSettings => 'Открыть настройки симулятора';

  @override
  String get eyeEngine => 'Живой взгляд';

  @override
  String get eyeEngineHint => 'Debug-управление эмоцией процедурных глаз.';

  @override
  String get eyeEmotionNeutral => 'Спокойный';

  @override
  String get eyeEmotionHappy => 'Радостный';

  @override
  String get eyeEmotionSleepy => 'Сонный';

  @override
  String get eyeEmotionSurprised => 'Удивлённый';

  @override
  String get blinkNow => 'Моргнуть';

  @override
  String get addImage => 'Добавить образ';

  @override
  String get photoLook => 'Фото';

  @override
  String get homeLookOriginal => 'Оригинал';

  @override
  String get homeLookMint => 'Мятный';

  @override
  String get homeLookLilac => 'Лиловый';

  @override
  String get homeLookPhoto => 'Моё фото';

  @override
  String get myContent => 'Мои образы';

  @override
  String get wardrobeAccent => 'hot girl closet';

  @override
  String get wardrobeLooksTab => 'Образы';

  @override
  String get wardrobePhotosTab => 'Мои фото';

  @override
  String get wardrobeOnDevice => 'НА БРЕЛОКЕ';

  @override
  String get wardrobeCurrentLookMeta => 'feeling flirty';

  @override
  String get wardrobeWorn => 'НА МНЕ';

  @override
  String get wardrobeLoadingStatus => 'СИНХРОНИЗАЦИЯ';

  @override
  String get wardrobeLoadingTitle => 'Раскладываем блеск…';

  @override
  String get wardrobeLoadingMessage => 'Образы появятся через мгновение';

  @override
  String get wardrobeLoadingSemantics => 'Гардероб загружается';

  @override
  String get wardrobeEmptyBadge => 'ТВОЙ ПЕРВЫЙ LOOK';

  @override
  String get wardrobeEmptyCount => '0 ОБРАЗОВ';

  @override
  String get createFirstLook => 'Создать первый образ';

  @override
  String get addPhoto => 'Добавить фото';

  @override
  String get wardrobeEmptyAccent => 'you bring the fantasy';

  @override
  String get wardrobeSceneErrorTitle => 'Гардероб не открылся';

  @override
  String get wardrobeSceneErrorMessage =>
      'Попробуй ещё раз — твои образы останутся на месте.';

  @override
  String get addLookShort => 'Добавить';

  @override
  String get createLookStep => 'CREATE A LOOK · 1/3';

  @override
  String get createLookTitle => 'Твоя история';

  @override
  String get createLookAccent => 'make it yours';

  @override
  String get createLookCropStep => 'CREATE A LOOK · 2/3';

  @override
  String get createLookCropTitle => 'Круглая обрезка';

  @override
  String get createLookCropAccent => 'center your fantasy';

  @override
  String get movePhotoInsideCircle => 'Перемещай фото внутри круга';

  @override
  String get pinchZoomAccent => 'pinch, zoom, kiss';

  @override
  String get zoomLabel => 'МАСШТАБ';

  @override
  String get autoCenter => 'Автоцентр';

  @override
  String get nextAction => 'Дальше';

  @override
  String get nextLightColorHint => 'Дальше настроим свет и цвет';

  @override
  String get createLookBeautyStep => 'CREATE A LOOK · 3/3';

  @override
  String get createLookBeautyTitle => 'Свет и цвет';

  @override
  String get createLookBeautyAccent => 'make it iconic';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get glowingAccent => 'she’s glowing';

  @override
  String get moodLabel => 'НАСТРОЕНИЕ';

  @override
  String get candyGloss => 'Candy Gloss';

  @override
  String get pearlDoll => 'Pearl Doll';

  @override
  String get clubKiss => 'Club Kiss';

  @override
  String get fineTuneLabel => 'ТОНКАЯ НАСТРОЙКА';

  @override
  String get glowLabel => 'Сияние';

  @override
  String get warmthLabel => 'Тепло';

  @override
  String get lookAppearsInWardrobe => 'Образ появится в «Моих образах»';

  @override
  String get choosePhoto => 'Выбрать фото';

  @override
  String get photoFormatsHint => 'JPG / PNG · лицо или любимый кадр';

  @override
  String get photoFantasyAccent => 'your face, your fantasy';

  @override
  String get inspiration => 'Вдохновение';

  @override
  String get inspirationOriginal => 'glossy';

  @override
  String get inspirationMint => 'mint kiss';

  @override
  String get inspirationLilac => 'dreamy';

  @override
  String get inspirationPhoto => 'my photo';

  @override
  String get prepareForScreen => 'Подготовим для экрана';

  @override
  String get circularCrop => 'Круглая\nобрезка';

  @override
  String get lightAndColor => 'Свет и\nцвет';

  @override
  String get chromeKissFeature => 'Chrome\nKiss';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get choosePhotoToContinue => 'Выбери фото, чтобы продолжить.';

  @override
  String get homeTab => 'Главная';

  @override
  String get looksTab => 'Образы';

  @override
  String get ritualsTab => 'Ритуалы';

  @override
  String get profileTab => 'Профиль';

  @override
  String get wardrobeIntro =>
      'Выбирайте настроение, примеряйте и создавайте свои образы.';

  @override
  String get myContentEmptyTitle => 'Гардероб пока пуст';

  @override
  String get myContentEmptyMessage =>
      'Создай первый образ — Luna примерит его сразу и сохранит для следующего настроения.';

  @override
  String get emptyLookPreview => 'Пустое место для нового образа';

  @override
  String get userImage => 'ВАШЕ ФОТО';

  @override
  String get setAsCurrent => 'Надеть';

  @override
  String get wearLook => 'Надеть';

  @override
  String get lookIsWorn => 'Надето';

  @override
  String get lookIsActive => 'СЕЙЧАС НА БРЕЛОКЕ';

  @override
  String get lookReady => 'ГОТОВ К ПРИМЕРКЕ';

  @override
  String get editCrop => 'Изменить кадрирование';

  @override
  String get delete => 'Удалить';

  @override
  String get deleteImageTitle => 'Удалить образ?';

  @override
  String get deleteImageMessage =>
      'Образ и исходное фото будут удалены с этого устройства.';

  @override
  String get imageChangesSaved => 'Изменения кадра сохранены.';

  @override
  String get imageDeleted => 'Образ удалён.';

  @override
  String get imageSetAsCurrent => 'Образ надет на брелок.';

  @override
  String get processingImage => 'Обрабатываем…';

  @override
  String get imageEditorTitle => 'Настроить кадр';

  @override
  String get createLook => 'Создать образ';

  @override
  String get adjustLookCrop => 'Настроить кадр';

  @override
  String get saveLook => 'Сохранить образ';

  @override
  String get saveLookChanges => 'Сохранить изменения';

  @override
  String get preparingLook => 'Подготавливаем…';

  @override
  String get lookSaved => 'образ сохранён';

  @override
  String get imageEditorHint =>
      'Перемещайте фото и сведите пальцы, чтобы настроить круглый кадр.';

  @override
  String get imageCropPreview => 'Предпросмотр круглого образа';

  @override
  String get imageCropGestureHint =>
      'Перемещайте фото и сведите пальцы, чтобы изменить масштаб.';

  @override
  String get rotate => 'Повернуть';

  @override
  String get reset => 'Сбросить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get imageSaved => 'Образ сохранён в гардеробе.';

  @override
  String get imageUnsupported =>
      'Файл повреждён или этот формат изображения не поддерживается.';

  @override
  String get imageReadFailed => 'Не удалось прочитать выбранное изображение.';

  @override
  String get imageProcessingFailed => 'Не удалось обработать изображение.';

  @override
  String get imageStorageFailed =>
      'Не удалось сохранить изображение на устройстве.';

  @override
  String get imagePersistenceFailed =>
      'Не удалось сохранить данные изображения.';

  @override
  String get imageDeviceFallbackFailed =>
      'Не удалось безопасно сменить активную сцену.';

  @override
  String get photoImportLabel => 'PHOTO IMPORT';

  @override
  String get photoImportErrorTitle => 'Фото не открылось';

  @override
  String get photoImportUnchanged => 'Файл не изменён · можно выбрать другой';

  @override
  String get chooseAnotherPhoto => 'Выбрать другое фото';

  @override
  String get returnBack => 'Вернуться назад';

  @override
  String get statusReady => 'НА СВЯЗИ';

  @override
  String get statusConnecting => 'ПОДКЛЮЧЕНИЕ';

  @override
  String get statusDiscovering => 'НАСТРОЙКА';

  @override
  String get statusDisconnected => 'НЕ В СЕТИ';

  @override
  String get statusDisconnecting => 'ОТКЛЮЧЕНИЕ';

  @override
  String percentValue(int value) {
    return '$value%';
  }
}
