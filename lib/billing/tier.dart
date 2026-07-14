enum AccountRequirement { none, required, optional }

enum SummaryStyle { basic, oneOnOne, standup, salesCall, interview, lecture, doctorVisit }

enum ExportTarget {
  copy,
  shareSheet,
  appleReminders,
  appleNotes,
  markdown,
  googleDocs,
  notion,
  obsidian,
  slack;

  /// True if reaching this destination requires a network call.
  ///
  /// Obsidian is deliberately NOT a cloud destination — it writes a Markdown
  /// file into a local vault folder and never touches the network. The other
  /// three POST to a third-party API.
  ///
  /// The Privacy tier is *defined* by the absence of these, so this is the
  /// single source of truth. Never hand-maintain a parallel list: add a new
  /// target here and [Tier.availableExports] filters it out of Privacy for
  /// free.
  bool get isCloudDestination => switch (this) {
        ExportTarget.googleDocs ||
        ExportTarget.notion ||
        ExportTarget.slack =>
          true,
        ExportTarget.copy ||
        ExportTarget.shareSheet ||
        ExportTarget.appleReminders ||
        ExportTarget.appleNotes ||
        ExportTarget.markdown ||
        ExportTarget.obsidian =>
          false,
      };
}

enum Tier {
  // 4 tiers total — collapsed from 6 after looking at the market (Otter /
  // Granola / Fathom / SuperWhisper / MacWhisper all settled at 3-4 SKUs).
  // FreePlus violated the no-account-required Karpathy criterion for trivial
  // quota bump; Starter was redundant with Pro. Lifetime-only — Karpathy
  // moat is "no subscriptions". Cloud Gemini quota + feature presence +
  // model-quality tier do the differentiation. Recording is unlimited
  // everywhere because Voice Memos / Samsung Recorder are unlimited+free.
  free(
    priceUsd: 0,
    account: AccountRequirement.none,
    cloudSummariesPerMonth: 5, // bumped 2→5 to match Fathom's free tier
    topUpsEnabled: true,
    personaTemplates: [SummaryStyle.basic],
    exports: [ExportTarget.copy, ExportTarget.shareSheet],
    speakerLabels: true,
    watermark: true,
  ),
  pro(
    priceUsd: 49, // bumped 39→49 for sustainability buffer; still competitive with mobile Whisper-app market (Whisper Notes $6.99, MacWhisper App Store $99)
    account: AccountRequirement.optional,
    cloudSummariesPerMonth: 100, // bumped 50→100 — more competitive
    topUpsEnabled: true,
    personaTemplates: SummaryStyle.values,
    exports: [
      ExportTarget.copy,
      ExportTarget.shareSheet,
      ExportTarget.appleReminders,
      ExportTarget.appleNotes,
      ExportTarget.markdown,
    ],
    speakerLabels: true,
    crossMeetingSearch: true,
    autoSegment: true,
  ),
  privacy(
    priceUsd: 69, // slight premium over Pro — signals "this is the special SKU" for the verifiable-no-network buyer
    account: AccountRequirement.optional,
    cloudSummariesEnabled: false, // verifiable no-network
    cloudExportsEnabled: false, // Notion / Slack / Google Docs are network calls
    cloudTranscriptionEnabled: false, // no Deepgram — Whisper only, structurally
    personaTemplates: SummaryStyle.values,
    // Offline destinations only. Obsidian is a local vault file write, so it
    // stays. This list used to be ExportTarget.values, which silently shipped
    // Notion/Slack/Google Docs on the tier whose entire promise is "this build
    // cannot reach the network" — [availableExports] now enforces that
    // regardless of what is written here.
    exports: [
      ExportTarget.copy,
      ExportTarget.shareSheet,
      ExportTarget.appleReminders,
      ExportTarget.appleNotes,
      ExportTarget.markdown,
      ExportTarget.obsidian,
    ],
    speakerLabels: true,
    crossMeetingSearch: true,
    autoSegment: true,
  ),
  power(
    priceUsd: 99, // sustainability buffer for BYOK + MCP + workflow exports; matches MacWhisper Mac App Store lifetime price
    account: AccountRequirement.optional,
    cloudSummariesPerMonth: null, // unlimited via BYOK
    byok: true,
    personaTemplates: SummaryStyle.values, // plus custom prompts at runtime
    exports: ExportTarget.values, // + Notion / Slack / Obsidian / GDocs
    speakerLabels: true,
    crossMeetingSearch: true,
    autoSegment: true,
  );

  const Tier({
    required this.priceUsd,
    required this.account,
    this.cloudSummariesPerMonth = 0,
    this.cloudSummariesEnabled = true,
    this.cloudExportsEnabled = true,
    this.cloudTranscriptionEnabled = true,
    this.topUpsEnabled = false,
    this.byok = false,
    this.personaTemplates = const [SummaryStyle.basic],
    this.exports = const [ExportTarget.copy, ExportTarget.shareSheet],
    this.speakerLabels = false,
    this.crossMeetingSearch = false,
    this.autoSegment = false,
    this.watermark = false,
  });

  final int priceUsd;
  final AccountRequirement account;

  /// Cloud Gemini summary quota — the only resource with real $ cost to us.
  /// null = unlimited (Power tier via BYOK). Recording length / meetings-per-
  /// day / hours-per-month are intentionally NOT capped at any tier: Whisper
  /// is on-device with zero marginal cost, and the OS-bundled voice recorders
  /// (Voice Memos / Samsung / Google) all give unlimited capture.
  final int? cloudSummariesPerMonth;

  /// If false, the cloud-summary option is removed from the UI entirely.
  /// Privacy tier sets this to false (verifiable no-network).
  final bool cloudSummariesEnabled;

  /// If false, export destinations that post to a third-party API
  /// (Notion / Slack / Google Docs) are removed. Privacy tier sets this to
  /// false — see [availableExports], which enforces it rather than trusting
  /// each call site to remember.
  final bool cloudExportsEnabled;

  /// If false, the cloud-transcription (Deepgram) engine is never offered and
  /// never constructed. Privacy tier sets this to false, so Whisper is the only
  /// ASR path — the same structural guarantee AsrRouter already makes.
  ///
  /// Note this gates *availability*, not the default: on every other tier cloud
  /// transcription is available but still OFF until the user turns it on.
  /// On-device stays the default everywhere.
  final bool cloudTranscriptionEnabled;

  /// Whether the user can buy one-time top-up packs for cloud summaries.
  final bool topUpsEnabled;

  /// Whether the user supplies their own API key (Power tier).
  final bool byok;

  final List<SummaryStyle> personaTemplates;
  final List<ExportTarget> exports;
  final bool speakerLabels;
  final bool crossMeetingSearch;
  final bool autoSegment;
  final bool watermark;

  /// The export destinations actually offered to this tier.
  ///
  /// Use this, never [exports], anywhere a user-facing list is built. When
  /// [cloudExportsEnabled] is false every network destination is stripped, so
  /// the Privacy tier's "this build cannot reach the network" promise holds
  /// even if someone later adds a cloud target to its [exports] list by
  /// mistake. Defence in depth: the list is correct AND the filter enforces it.
  List<ExportTarget> get availableExports => cloudExportsEnabled
      ? exports
      : exports.where((t) => !t.isCloudDestination).toList(growable: false);

  /// Which on-device Gemma 4 variant the tier is entitled to download.
  /// Free → E2B (smaller, 2.4 GB, weaker reasoning). Pro+ → E4B (larger,
  /// 4.3 GB, noticeably better summaries + larger effective context).
  /// On-device summary *count* is unlimited on every tier — only quality
  /// differs. (Apple FM on iOS 26+ is layered on top wherever available.)
  GemmaVariant get gemmaVariant => switch (this) {
        Tier.free => GemmaVariant.e2b,
        _ => GemmaVariant.e4b,
      };

  /// Whisper model ceiling for *final* transcription. Free → base.en
  /// (~140 MB, competitive with Apple Voice Memos / Samsung Transcript
  /// Assist accuracy). Pro+ → small.en (~466 MB, noticeably better on
  /// accented + noisy speech). Note: live captions during recording always
  /// use tiny.en regardless of tier — fast streaming model is the right
  /// shape for the every-5s chunk loop. Otter / Granola do the same split.
  WhisperCeiling get whisperCeiling => switch (this) {
        Tier.free => WhisperCeiling.baseEn,
        _ => WhisperCeiling.smallEn,
      };
}

enum GemmaVariant {
  e2b(
    modelId: 'gemma-4-e2b-it',
    displayName: 'Gemma 4 E2B',
    approxBytes: 2400 * 1000 * 1000,
    defaultUrl:
        'https://huggingface.co/litert-community/Gemma-4-E2B-it/resolve/main/Gemma-4-E2B-it.litertlm',
  ),
  e4b(
    modelId: 'gemma-4-e4b-it',
    displayName: 'Gemma 4 E4B',
    approxBytes: 4300 * 1000 * 1000,
    defaultUrl:
        'https://huggingface.co/litert-community/Gemma-4-E4B-it/resolve/main/Gemma-4-E4B-it.litertlm',
  );

  const GemmaVariant({
    required this.modelId,
    required this.displayName,
    required this.approxBytes,
    required this.defaultUrl,
  });

  final String modelId;
  final String displayName;
  final int approxBytes;
  final String defaultUrl;
}

enum WhisperCeiling { tinyEn, baseEn, smallEn }

/// Top-up packs for cloud summaries. One-time IAP, never expire.
/// Available on Free, Free+, Starter, Pro. N/A for Privacy (no cloud) and
/// Power (BYOK covers it).
enum TopUpPack {
  small(summaries: 25, priceUsd: 2.99),
  medium(summaries: 100, priceUsd: 9.99),
  large(summaries: 500, priceUsd: 39.99);

  const TopUpPack({required this.summaries, required this.priceUsd});

  final int summaries;
  final double priceUsd;
}
