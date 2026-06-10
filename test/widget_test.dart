// Placeholder smoke test. The real app boots a bunch of native plugins
// (Drift, secure storage, IAP, audio recorder) that aren't available in
// the headless test environment, so we don't pumpWidget(RecapApp) here.
// Replace with proper widget tests per-screen once UI flows have stabilized.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
