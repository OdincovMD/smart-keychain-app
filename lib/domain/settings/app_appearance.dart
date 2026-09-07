enum AppAppearance {
  obsidian('obsidian'),
  pearl('pearl'),
  system('system');

  const AppAppearance(this.storageValue);

  final String storageValue;

  static AppAppearance fromStorageValue(String value) {
    return switch (value) {
      'obsidian' => AppAppearance.obsidian,
      'pearl' => AppAppearance.pearl,
      'system' => AppAppearance.system,
      _ => AppAppearance.system,
    };
  }
}
