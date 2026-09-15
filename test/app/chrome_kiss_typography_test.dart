import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keychain_app/app/app_theme.dart';
import 'package:smart_keychain_app/app/chrome_kiss_theme.dart';

void main() {
  test(
    'Chrome Kiss typography maps display and UI roles to approved fonts',
    () {
      final typography = ChromeKissTypography.fromColors(
        ChromeKissColors.obsidian,
      );

      expect(typography.display.fontFamily, 'CormorantGaramond');
      expect(typography.title.fontFamily, 'CormorantGaramond');
      expect(typography.body.fontFamily, 'Manrope');
      expect(typography.label.fontFamily, 'Manrope');
      expect(typography.status.fontFamily, 'Manrope');
    },
  );

  test('Material editorial and functional roles use approved families', () {
    final theme = buildAppTheme();

    expect(theme.textTheme.displaySmall?.fontFamily, 'CormorantGaramond');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'CormorantGaramond');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Manrope');
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Manrope');
    expect(theme.textTheme.labelLarge?.fontFamily, 'Manrope');
  });
}
