import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';
import '../../../data/off/off_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _newsletter = false;
  bool _busy = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final trimmedUser = _userCtrl.text.trim();
      final auth = context.read<OffAuth>();
      final status = await OpenFoodAPIClient.register(
        user: User(userId: trimmedUser, password: _passCtrl.text),
        name: _nameCtrl.text.trim().isEmpty ? trimmedUser : _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        newsletter: _newsletter,
      );
      final dynamic statusCode = status.status;
      final bool success =
          statusCode == 201 || statusCode == 'status ok' || statusCode == 'status_ok' || statusCode == 1;
      if (success) {
        await auth.save(trimmedUser, _passCtrl.text);
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        final msg = status.error ?? 'Sign up failed';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Display name (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _newsletter,
                onChanged: _busy ? null : (v) => setState(() => _newsletter = v ?? false),
                title: const Text('Subscribe to newsletter'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Creating...' : 'Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
