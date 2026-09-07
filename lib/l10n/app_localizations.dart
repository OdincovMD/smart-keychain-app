import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Умный брелок'**
  String get appTitle;

  /// No description provided for @discoveryEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'ВИРТУАЛЬНАЯ МАСТЕРСКАЯ'**
  String get discoveryEyebrow;

  /// No description provided for @discoveryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите брелок'**
  String get discoveryTitle;

  /// No description provided for @discoverySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подключите демо-устройство и попробуйте сцены без настоящего брелока.'**
  String get discoverySubtitle;

  /// No description provided for @demoKeychain.
  ///
  /// In ru, this message translates to:
  /// **'Demo Keychain'**
  String get demoKeychain;

  /// No description provided for @demoMode.
  ///
  /// In ru, this message translates to:
  /// **'ДЕМО-РЕЖИМ'**
  String get demoMode;

  /// No description provided for @batteryPercent.
  ///
  /// In ru, this message translates to:
  /// **'Заряд {value}%'**
  String batteryPercent(int value);

  /// No description provided for @connect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключаем…'**
  String get connecting;

  /// No description provided for @discovering.
  ///
  /// In ru, this message translates to:
  /// **'Настраиваем экран…'**
  String get discovering;

  /// No description provided for @connected.
  ///
  /// In ru, this message translates to:
  /// **'Подключено'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get disconnected;

  /// No description provided for @disconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Отключаем…'**
  String get disconnecting;

  /// No description provided for @disconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get disconnect;

  /// No description provided for @deviceHomeEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'МОЙ БРЕЛОК'**
  String get deviceHomeEyebrow;

  /// No description provided for @deviceReady.
  ///
  /// In ru, this message translates to:
  /// **'Готов к командам'**
  String get deviceReady;

  /// No description provided for @sceneLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Настроение экрана'**
  String get sceneLibrary;

  /// No description provided for @sceneLibrarySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите образ, который появится на брелоке.'**
  String get sceneLibrarySubtitle;

  /// No description provided for @wardrobe.
  ///
  /// In ru, this message translates to:
  /// **'Гардероб'**
  String get wardrobe;

  /// No description provided for @allLooks.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get allLooks;

  /// No description provided for @allLooksTitle.
  ///
  /// In ru, this message translates to:
  /// **'Все образы'**
  String get allLooksTitle;

  /// No description provided for @moodNeutral.
  ///
  /// In ru, this message translates to:
  /// **'СПОКОЙНАЯ'**
  String get moodNeutral;

  /// No description provided for @presenceNeutral.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня просто рядом.'**
  String get presenceNeutral;

  /// No description provided for @changeLook.
  ///
  /// In ru, this message translates to:
  /// **'Сменить образ'**
  String get changeLook;

  /// No description provided for @tryingOn.
  ///
  /// In ru, this message translates to:
  /// **'Примеряем…'**
  String get tryingOn;

  /// No description provided for @activeScene.
  ///
  /// In ru, this message translates to:
  /// **'НА ЭКРАНЕ'**
  String get activeScene;

  /// No description provided for @installScene.
  ///
  /// In ru, this message translates to:
  /// **'Установить'**
  String get installScene;

  /// No description provided for @installed.
  ///
  /// In ru, this message translates to:
  /// **'Установлено'**
  String get installed;

  /// No description provided for @installing.
  ///
  /// In ru, this message translates to:
  /// **'Отправляем…'**
  String get installing;

  /// No description provided for @brightness.
  ///
  /// In ru, this message translates to:
  /// **'Яркость'**
  String get brightness;

  /// No description provided for @brightnessHint.
  ///
  /// In ru, this message translates to:
  /// **'Команда отправится после отпускания ползунка.'**
  String get brightnessHint;

  /// No description provided for @simulatorSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки симулятора'**
  String get simulatorSettings;

  /// No description provided for @simulatorSettingsHint.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте задержку команд и поведение живого экрана.'**
  String get simulatorSettingsHint;

  /// No description provided for @appearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get appearance;

  /// No description provided for @appearanceHint.
  ///
  /// In ru, this message translates to:
  /// **'Одна система Chrome Kiss в тёмной или светлой подаче.'**
  String get appearanceHint;

  /// No description provided for @appearanceObsidian.
  ///
  /// In ru, this message translates to:
  /// **'Obsidian'**
  String get appearanceObsidian;

  /// No description provided for @appearancePearl.
  ///
  /// In ru, this message translates to:
  /// **'Pearl'**
  String get appearancePearl;

  /// No description provided for @appearanceSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get appearanceSystem;

  /// No description provided for @latency.
  ///
  /// In ru, this message translates to:
  /// **'Задержка'**
  String get latency;

  /// No description provided for @latencyValue.
  ///
  /// In ru, this message translates to:
  /// **'{value} мс'**
  String latencyValue(int value);

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @sceneLivingEyes.
  ///
  /// In ru, this message translates to:
  /// **'Живой взгляд'**
  String get sceneLivingEyes;

  /// No description provided for @sceneLivingEyesDescription.
  ///
  /// In ru, this message translates to:
  /// **'Сам моргает, наблюдает и меняет настроение.'**
  String get sceneLivingEyesDescription;

  /// No description provided for @sceneMintEyes.
  ///
  /// In ru, this message translates to:
  /// **'Мятный взгляд'**
  String get sceneMintEyes;

  /// No description provided for @sceneMintEyesDescription.
  ///
  /// In ru, this message translates to:
  /// **'Спокойные глаза с тёплой искрой.'**
  String get sceneMintEyesDescription;

  /// No description provided for @sceneSunnyFriend.
  ///
  /// In ru, this message translates to:
  /// **'Солнечный друг'**
  String get sceneSunnyFriend;

  /// No description provided for @sceneSunnyFriendDescription.
  ///
  /// In ru, this message translates to:
  /// **'Коралловое настроение на весь день.'**
  String get sceneSunnyFriendDescription;

  /// No description provided for @connectionError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить команду устройства.'**
  String get connectionError;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать снова'**
  String get retry;

  /// No description provided for @devicePreviewLabel.
  ///
  /// In ru, this message translates to:
  /// **'Виртуальный экран брелока'**
  String get devicePreviewLabel;

  /// No description provided for @openSimulatorSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки симулятора'**
  String get openSimulatorSettings;

  /// No description provided for @eyeEngine.
  ///
  /// In ru, this message translates to:
  /// **'Живой взгляд'**
  String get eyeEngine;

  /// No description provided for @eyeEngineHint.
  ///
  /// In ru, this message translates to:
  /// **'Debug-управление эмоцией процедурных глаз.'**
  String get eyeEngineHint;

  /// No description provided for @eyeEmotionNeutral.
  ///
  /// In ru, this message translates to:
  /// **'Спокойный'**
  String get eyeEmotionNeutral;

  /// No description provided for @eyeEmotionHappy.
  ///
  /// In ru, this message translates to:
  /// **'Радостный'**
  String get eyeEmotionHappy;

  /// No description provided for @eyeEmotionSleepy.
  ///
  /// In ru, this message translates to:
  /// **'Сонный'**
  String get eyeEmotionSleepy;

  /// No description provided for @eyeEmotionSurprised.
  ///
  /// In ru, this message translates to:
  /// **'Удивлённый'**
  String get eyeEmotionSurprised;

  /// No description provided for @blinkNow.
  ///
  /// In ru, this message translates to:
  /// **'Моргнуть'**
  String get blinkNow;

  /// No description provided for @addImage.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get addImage;

  /// No description provided for @myContent.
  ///
  /// In ru, this message translates to:
  /// **'Мои фото'**
  String get myContent;

  /// No description provided for @myContentEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся ваши фото'**
  String get myContentEmptyTitle;

  /// No description provided for @myContentEmptyMessage.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте изображение и настройте кадр для круглого экрана брелока.'**
  String get myContentEmptyMessage;

  /// No description provided for @userImage.
  ///
  /// In ru, this message translates to:
  /// **'ВАШЕ ФОТО'**
  String get userImage;

  /// No description provided for @setAsCurrent.
  ///
  /// In ru, this message translates to:
  /// **'На экран'**
  String get setAsCurrent;

  /// No description provided for @editCrop.
  ///
  /// In ru, this message translates to:
  /// **'Изменить кадр'**
  String get editCrop;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @deleteImageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото?'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageMessage.
  ///
  /// In ru, this message translates to:
  /// **'Оригинал, настроенный кадр и сцена будут удалены с этого устройства.'**
  String get deleteImageMessage;

  /// No description provided for @imageChangesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Изменения кадра сохранены.'**
  String get imageChangesSaved;

  /// No description provided for @imageDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Фото удалено.'**
  String get imageDeleted;

  /// No description provided for @imageSetAsCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Фото установлено на экран брелока.'**
  String get imageSetAsCurrent;

  /// No description provided for @processingImage.
  ///
  /// In ru, this message translates to:
  /// **'Обрабатываем…'**
  String get processingImage;

  /// No description provided for @imageEditorTitle.
  ///
  /// In ru, this message translates to:
  /// **'Кадр для брелока'**
  String get imageEditorTitle;

  /// No description provided for @imageEditorHint.
  ///
  /// In ru, this message translates to:
  /// **'Перемещайте изображение и сведите пальцы, чтобы настроить круглый кадр.'**
  String get imageEditorHint;

  /// No description provided for @imageCropPreview.
  ///
  /// In ru, this message translates to:
  /// **'Предпросмотр круглого кадра'**
  String get imageCropPreview;

  /// No description provided for @rotate.
  ///
  /// In ru, this message translates to:
  /// **'Повернуть'**
  String get rotate;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @imageSaved.
  ///
  /// In ru, this message translates to:
  /// **'Фото сохранено в библиотеке.'**
  String get imageSaved;

  /// No description provided for @imageUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Файл повреждён или этот формат изображения не поддерживается.'**
  String get imageUnsupported;

  /// No description provided for @imageReadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать выбранное изображение.'**
  String get imageReadFailed;

  /// No description provided for @imageProcessingFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать изображение.'**
  String get imageProcessingFailed;

  /// No description provided for @imageStorageFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить изображение на устройстве.'**
  String get imageStorageFailed;

  /// No description provided for @imagePersistenceFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить данные изображения.'**
  String get imagePersistenceFailed;

  /// No description provided for @imageDeviceFallbackFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось безопасно сменить активную сцену.'**
  String get imageDeviceFallbackFailed;

  /// No description provided for @statusReady.
  ///
  /// In ru, this message translates to:
  /// **'НА СВЯЗИ'**
  String get statusReady;

  /// No description provided for @statusConnecting.
  ///
  /// In ru, this message translates to:
  /// **'ПОДКЛЮЧЕНИЕ'**
  String get statusConnecting;

  /// No description provided for @statusDiscovering.
  ///
  /// In ru, this message translates to:
  /// **'НАСТРОЙКА'**
  String get statusDiscovering;

  /// No description provided for @statusDisconnected.
  ///
  /// In ru, this message translates to:
  /// **'НЕ В СЕТИ'**
  String get statusDisconnected;

  /// No description provided for @statusDisconnecting.
  ///
  /// In ru, this message translates to:
  /// **'ОТКЛЮЧЕНИЕ'**
  String get statusDisconnecting;

  /// No description provided for @percentValue.
  ///
  /// In ru, this message translates to:
  /// **'{value}%'**
  String percentValue(int value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
