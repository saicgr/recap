import '../../billing/tier.dart';
import '../../data/database.dart';
import 'neon_auth.dart';
import 'sync_config.dart';

/// The single place the whole sync subsystem is switched on — or, on the Privacy
/// tier, never constructed at all.
///
/// This is the structural half of the Karpathy guarantee. It is NOT a runtime
/// flag that code remembers to check; it is the fact that on Privacy, `create`
/// returns null and no NeonAuth, no DataApi, no SyncEngine object is ever built,
/// so there is no socket that could open. Verifiable by reading this file, and
/// enforced by test/privacy/.
///
/// Called ONCE, from main.dart, with the tier already resolved from disk. It is
/// deliberately not given a way to be re-enabled after the fact: a Privacy build
/// has no sync object, full stop.
class SyncManager {
  SyncManager._(this.auth);

  final NeonAuth auth;

  /// Build the sync subsystem, or return null when it must not exist.
  ///
  /// Returns null — meaning "no sync objects were created" — when:
  ///   - the tier is Privacy (structural no-network guarantee), or
  ///   - the backend endpoints are not configured (a build with the defaults
  ///     stripped simply has no sync rather than dialling a dead host).
  ///
  /// FAILS CLOSED: passed an unknown/failed tier read, the caller must treat it
  /// as Privacy. The caller resolves the tier synchronously before runApp() and
  /// throws rather than defaulting to a cloud-capable build.
  static SyncManager? create({
    required Tier tier,
    // ignore: avoid_unused_constructor_parameters
    required AppDb db,
  }) {
    if (tier == Tier.privacy) {
      // The entire point. Do not construct anything that can reach the network.
      return null;
    }
    if (!SyncConfig.isConfigured) return null;

    return SyncManager._(NeonAuth(authBaseUrl: SyncConfig.authBaseUrl));
  }

  bool get isSignedIn => auth.isSignedIn;
}
