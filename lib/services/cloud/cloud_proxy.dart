/// The contract between the app and its single backend keyholder — the Render
/// proxy in `render-proxy/`, live at https://recap-proxy.onrender.com.
///
///   POST /v1/register   {install_id}                      -> {token}
///   POST /v1/summarize  {persona_key, prompt, transcript} -> {text, model_id}
///        headers: Authorization: Bearer <token>
///                 X-Install-Id:  <installId>
///
/// `token = HMAC-SHA256(installId, PEPPER)`, issued once by /v1/register and
/// cached in the keychain. The pepper is server-only, so a token the app makes
/// up is rejected — which is the whole point: the retired Cloudflare Worker
/// accepted any 64-hex string and was an open proxy to a billed Gemini key.
///
/// The app holds no API keys. The other half of this contract lives in
/// `render-proxy/src/auth.ts` and `render-proxy/src/server.ts` — keep in sync.
library;

/// The deployed Render service. Override with
/// `--dart-define=RECAP_PROXY_URL=...`, or per-install in Settings.
const kDefaultProxyUrl = 'https://recap-proxy.onrender.com';

/// Deliberately not a real host. A build that strips the default lands here and
/// reports "cloud unavailable" instead of dialling something dead.
const kPlaceholderProxyUrl = 'https://recap-proxy.example.onrender.com';

/// The retired Cloudflare Worker. Any install that stored this URL must be
/// migrated off it: it is being un-deployed, and it would 404 forever.
const kRetiredWorkerHostFragment = 'workers.dev';

/// True when [raw] names a proxy worth calling.
bool isConfiguredProxyUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty || url == kPlaceholderProxyUrl) return false;
  final uri = Uri.tryParse(url);
  return uri != null && uri.hasScheme && uri.host.isNotEmpty;
}

/// [isConfiguredProxyUrl] plus normalization — strips a trailing slash so
/// '$base/v1/summarize' can never produce a double slash.
///
/// Throws rather than returning a fallback (CLAUDE.md: never silently degrade).
String requireConfiguredProxyUrl(String raw) {
  final url = raw.trim();
  if (!isConfiguredProxyUrl(url)) {
    throw CloudError(
      CloudFailureKind.notConfigured,
      'Cloud proxy URL is not configured ("$url").',
    );
  }
  return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

/// Why a cloud call failed. Callers switch on this rather than parsing strings.
enum CloudFailureKind {
  /// The tier has cloud structurally disabled (Privacy). Not a network error —
  /// we never left the device.
  disabled,

  /// No usable proxy URL.
  notConfigured,

  /// DNS/socket/TLS failure — airplane mode, captive portal, proxy down.
  offline,

  /// Sent, but the proxy did not answer in time.
  timeout,

  /// 401. Our token is not one this server would issue (pepper rotated, or the
  /// token predates the Render backend). We re-register once, then give up.
  unauthorized,

  /// 429. Hourly cap.
  rateLimited,

  /// 503. The proxy's shared daily budget is spent. Distinct from 429: waiting
  /// a minute will not help, waiting until tomorrow will.
  budgetExhausted,

  /// 402. The user's metered allowance (e.g. cloud-transcription minutes) is
  /// exhausted.
  quotaExhausted,

  /// Any other 4xx/5xx, including 502 (the upstream model provider failed).
  server,

  /// HTTP 200 with nothing usable in it.
  emptyResponse,
}

/// A cloud failure carrying enough context to act on.
///
/// Extends [StateError] to satisfy CLAUDE.md's "throw StateError with context,
/// never silently degrade", while staying switchable on [kind]. [toString] is
/// the bare message so the UI does not render "Bad state: ...".
class CloudError extends StateError {
  CloudError(this.kind, super.message);

  final CloudFailureKind kind;

  /// True when the identical request could succeed later with no user action.
  bool get isTransient =>
      kind == CloudFailureKind.offline ||
      kind == CloudFailureKind.timeout ||
      kind == CloudFailureKind.rateLimited ||
      kind == CloudFailureKind.budgetExhausted ||
      kind == CloudFailureKind.server;

  @override
  String toString() => message;
}

/// Keep proxy error bodies out of the UI at full length.
String truncateForError(String s) =>
    s.length > 400 ? '${s.substring(0, 400)}...' : s;
