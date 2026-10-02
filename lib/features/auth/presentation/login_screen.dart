import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic.dart';
import '../../../core/widgets/common.dart';
import 'session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _sendCode() async {
    if (!_emailValid) {
      showMessage(context, 'أدخل بريداً إلكترونياً صحيحاً', error: true);
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context,
        () => ref.read(authRepositoryProvider).sendEmailCode(_email.text));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeSent = ok;
    });
    if (ok) showMessage(context, 'أرسلنا رمز الدخول إلى بريدك');
  }

  Future<void> _verify() async {
    final code = toLatinDigits(_code.text.trim());
    if (code.length < 6) return;
    setState(() => _busy = true);
    await runGuarded(context,
        () => ref.read(authRepositoryProvider).verifyEmailCode(_email.text, code));
    if (mounted) setState(() => _busy = false);
    // التوجيه يتم تلقائياً عند تغيّر الجلسة
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 24),
            Text('بدّلها',
                style: theme.textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('أنت تملك ما لا تحتاجه.\nوغيرك يملك ما تحتاجه.',
                style: theme.textTheme.titleMedium?.copyWith(height: 1.6)),
            Text('بدّلها.',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 40),
            TextField(
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                maxLength: 8,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  labelText: 'رمز الدخول',
                  counterText: '',
                ),
                onChanged: (v) {
                  if (toLatinDigits(v.trim()).length >= 6) _verify();
                },
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _codeSent = false;
                          _code.clear();
                        }),
                child: const Text('تغيير البريد / إعادة الإرسال'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_codeSent ? 'دخول' : 'أرسل رمز الدخول'),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا نعرض بريدك أو رقمك لأي مستخدم آخر.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
