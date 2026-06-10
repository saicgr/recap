import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

class ByokScreen extends StatefulWidget {
  const ByokScreen({super.key});

  @override
  State<ByokScreen> createState() => _ByokScreenState();
}

class _ByokScreenState extends State<ByokScreen> {
  static const _storage = FlutterSecureStorage();
  static const _kKey = 'byok_api_key';
  static const _kProvider = 'byok_provider';

  String _provider = 'gemini';
  final _keyController = TextEditingController();
  bool _existing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _storage.read(key: _kProvider);
    final k = await _storage.read(key: _kKey);
    if (!mounted) return;
    setState(() {
      _provider = p ?? 'gemini';
      _existing = k != null;
    });
  }

  Future<void> _save() async {
    if (_keyController.text.trim().isEmpty) return;
    await _storage.write(key: _kProvider, value: _provider);
    await _storage.write(key: _kKey, value: _keyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved to keychain')),
    );
    setState(() {
      _existing = true;
      _keyController.clear();
    });
  }

  Future<void> _delete() async {
    await _storage.delete(key: _kKey);
    if (!mounted) return;
    setState(() => _existing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context)),
              title: Text('Bring your own key',
                  style: RT.subtitle.copyWith(color: t.textPrimary)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'Power tier · Route cloud summaries through your own provider key. Your key, your bill, no per-summary cap.',
                    style: RT.body.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Text('PROVIDER',
                      style: RT.caption.copyWith(color: t.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final p in const [
                          ('gemini', 'Google Gemini'),
                          ('openai', 'OpenAI'),
                          ('anthropic', 'Anthropic'),
                        ])
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _provider = p.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: p.$1 == 'anthropic'
                                        ? BorderSide.none
                                        : BorderSide(color: t.divider),
                                  ),
                                ),
                                child: Row(children: [
                                  Expanded(
                                    child: Text(p.$2,
                                        style: RT.body.copyWith(
                                            color: t.textPrimary)),
                                  ),
                                  if (_provider == p.$1)
                                    Icon(Icons.check,
                                        size: 16, color: t.accent),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(_existing ? 'REPLACE API KEY' : 'API KEY',
                      style: RT.caption.copyWith(color: t.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    cursorColor: t.accent,
                    style: RT.body.copyWith(color: t.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: t.surface,
                      hintText: 'sk-… / AIza… / etc.',
                      hintStyle: RT.body.copyWith(color: t.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Btn(label: 'Save', onPressed: _save),
                    const SizedBox(width: 12),
                    if (_existing)
                      Btn(
                        label: 'Delete saved key',
                        variant: BtnVariant.destructive,
                        onPressed: _delete,
                      ),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    'Stored in platform keychain (iOS Keychain / Android Keystore). Never written to disk in plaintext. Never sent anywhere except directly to the provider you select.',
                    style: RT.bodySm.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
