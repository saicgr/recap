/// Neon endpoints for the sync layer.
///
/// These are public URLs, not secrets — the security is the per-user JWT plus
/// Row-Level Security enforced inside Postgres, never a shared credential. The
/// app holds no database password and no service key; that is the whole reason
/// the Data API + RLS design was chosen over a connection string.
///
/// Overridable per build with --dart-define for staging vs production.
class SyncConfig {
  const SyncConfig._();

  static const authBaseUrl = String.fromEnvironment(
    'RECAP_NEON_AUTH_URL',
    defaultValue:
        'https://ep-cool-bonus-ajskwyal.neonauth.c-3.us-east-2.aws.neon.tech/neondb/auth',
  );

  static const dataApiUrl = String.fromEnvironment(
    'RECAP_NEON_DATA_API_URL',
    defaultValue:
        'https://ep-cool-bonus-ajskwyal.apirest.c-3.us-east-2.aws.neon.tech/neondb/rest/v1',
  );

  /// True only if the endpoints look real. Sync stays dormant otherwise, so a
  /// build that stripped the defaults simply has no sync rather than dialling a
  /// dead host.
  static bool get isConfigured =>
      authBaseUrl.startsWith('https://') && dataApiUrl.startsWith('https://');
}
