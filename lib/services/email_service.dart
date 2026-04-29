import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/app_config.dart';

/// Handles all outbound email delivery via SMTP.
///
/// All methods are fire-and-return — they never throw. A `false` return
/// value means the email could not be sent (network error, quota, etc.)
/// but the calling code should still treat the operation as continuing;
/// verification / recovery codes are held in-memory regardless.
class EmailService {
  EmailService._();

  static SmtpServer get _smtpServer => SmtpServer(
        AppConfig.smtpHost,
        port: AppConfig.smtpPort,
        username: AppConfig.smtpUsername,
        password: AppConfig.smtpPassword,
        ssl: AppConfig.smtpSsl,
      );

  // ── Public API ──────────────────────────────────────────────────────────

  /// Sends a 6-digit email-verification code to [toEmail].
  ///
  /// Returns `true` if the SMTP transaction succeeded.
  static Future<bool> sendVerificationEmail(
      String toEmail, String code) async {
    return _sendEmail(
      to: toEmail,
      subject: 'Me2Leads - Code de vérification',
      body: 'Bonjour,\n\n'
          'Votre code de vérification Me2Leads est : $code\n\n'
          'Ce code expire dans 10 minutes.\n\n'
          'Si vous n\'avez pas créé de compte Me2Leads, ignorez cet email.\n\n'
          '— L\'équipe Me2Leads',
    );
  }

  /// Sends a 6-digit password-recovery code to [toEmail].
  ///
  /// Returns `true` if the SMTP transaction succeeded.
  static Future<bool> sendRecoveryEmail(String toEmail, String code) async {
    return _sendEmail(
      to: toEmail,
      subject: 'Me2Leads - Code de récupération',
      body: 'Bonjour,\n\n'
          'Votre code de récupération Me2Leads est : $code\n\n'
          'Ce code expire dans 10 minutes.\n\n'
          'Si vous n\'avez pas demandé ce code, ignorez cet email.\n\n'
          '— L\'équipe Me2Leads',
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────

  static Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      final message = Message()
        ..from = Address(AppConfig.smtpUsername, 'Me2Leads')
        ..recipients.add(to)
        ..subject = subject
        ..text = body;

      await send(message, _smtpServer);
      return true;
    } catch (_) {
      // Email sending failed — the in-memory code is still valid.
      // Callers should not surface this error directly; the code flow
      // continues normally.
      return false;
    }
  }
}
