// ignore_for_file: constant_identifier_names

/// Application configuration with obfuscated credentials.
///
/// SMTP credentials are stored as XOR-obfuscated integer arrays.
/// The key cycles over each byte, so the plaintext never appears in the
/// compiled binary as a contiguous string literal.
///
/// Obfuscation method: XOR with a cycling key, so credentials never
/// appear as plaintext string literals in the compiled binary.
class AppConfig {
  AppConfig._();

  // ── SMTP ────────────────────────────────────────────────────────────────

  static String get smtpHost => _deobfuscate(const [
        62, 10, 32, 85, 79, 11, 5, 90, 30, 92, 83, 39,
      ]);

  static int get smtpPort => 465;

  static String get smtpUsername => _deobfuscate(const [
        46, 22, 33, 8, 20, 10, 26, 81, 81, 70, 95, 60, 11, 35, 22, 0,
        22, 36, 16, 24, 35, 24, 98, 6, 14, 9,
      ]);

  static String get smtpPassword => _deobfuscate(const [
        3, 57, 116, 80, 81, 81, 71, 0, 9, 7, 0, 107, 86, 87, 7, 31,
      ]);

  static bool get smtpSsl => true;

  // ── MySQL remote sync ───────────────────────────────────────────────────

  static String get mysqlHost => _deobfuscate(const [
        55, 11, 93, 87, 88, 82, 66, 6, 3, 31, 6, 99, 84, 81, 23, 20,
        90, 40, 13, 22, 56, 29, 40, 7, 79, 11, 5, 90, 30, 92, 83, 39,
      ]);

  static int get mysqlPort => 35500;

  static String get mysqlUsername => _deobfuscate(const [
        57, 28, 46, 10, 20, 5, 29, 83,
      ]);

  static String get mysqlPassword => _deobfuscate(const [
        14, 28, 112, 35, 9, 42, 26, 115, 114, 126, 114, 25,
      ]);

  static String get mysqlDatabase => _deobfuscate(const [
        57, 28, 42, 4, 20, 8, 7, 86, 66,
      ]);

  // ── Internal ────────────────────────────────────────────────────────────

  /// XOR deobfuscation. Key cycles over [data] by index modulo key length.
  static String _deobfuscate(List<int> data) {
    const key = 'MyLeads2026SecretKey';
    final result = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      result.writeCharCode(data[i] ^ key.codeUnitAt(i % key.length));
    }
    return result.toString();
  }
}
