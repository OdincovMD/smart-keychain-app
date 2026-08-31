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
  String get disconnected => 'Отключено';

  @override
  String get disconnecting => 'Отключаем…';

  @override
  String get disconnect => 'Отключить';

  @override
  String get deviceHomeEyebrow => 'МОЙ БРЕЛОК';

  @override
  String get deviceReady => 'Готов к командам';

  @override
  String get sceneLibrary => 'Настроение экрана';

  @override
  String get sceneLibrarySubtitle =>
      'Выберите образ, который появится на брелоке.';

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
  String get simulatorSettings => 'Задержка симулятора';

  @override
  String get simulatorSettingsHint =>
      'Проверьте, как интерфейс ведёт себя при медленном устройстве.';

  @override
  String get latency => 'Задержка';

  @override
  String latencyValue(int value) {
    return '$value мс';
  }

  @override
  String get close => 'Закрыть';

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
  String get devicePreviewLabel => 'Виртуальный экран брелока';

  @override
  String get openSimulatorSettings => 'Открыть настройки задержки';

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
