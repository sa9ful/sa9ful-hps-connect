import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/firebase_backend.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _login() {
    final backend = AppScope.backendOf(context);
    if (!backend.isDemo && !_formKey.currentState!.validate()) return;
    _run(() => backend.signInWithEmail(_id.text, _password.text));
  }

  Future<void> _forgot() async {
    if (_id.text.trim().isEmpty) {
      setState(
        () => _error = 'পাসওয়ার্ড রিসেটের জন্য আগে ইউজার আইডি বা ইমেইল লিখুন।',
      );
      return;
    }
    await _run(() => AppScope.backendOf(context).sendPasswordReset(_id.text));
    if (mounted && _error == null) {
      showSnack(context, 'পাসওয়ার্ড রিসেটের লিংক ইমেইলে পাঠানো হয়েছে।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = AppScope.backendOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (backend.isDemo) const _DemoBanner(),
                    const Center(child: SchoolLogo(size: 92)),
                    const SizedBox(height: 12),
                    const Text(
                      'HERITAGE PUBLIC SCHOOL\nFaridpur',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HpsColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'HPS CONNECT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HpsColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('login-id'),
                      controller: _id,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        hintText: 'User ID / Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'ইউজার আইডি বা ইমেইল লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onFieldSubmitted: (_) => _login(),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন'
                          : null,
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? true),
                        ),
                        const Expanded(
                          child: Text(
                            'Remember me',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: _busy ? null : _forgot,
                            child: const Text(
                              'Forgot Password?',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: HpsColors.important),
                        ),
                      ),
                    FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Or'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(backend.signInWithGoogle),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'অ্যাকাউন্ট নেই? সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HpsColors.warning),
      ),
      child: const Text(
        'ডেমো মোড: Firebase এখনো যুক্ত হয়নি। যেকোনো আইডি দিয়ে Login চাপুন, '
        'নমুনা ডেটা দিয়ে সব স্ক্রিন দেখা যাবে।',
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}
