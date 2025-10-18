import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/off/off_auth.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<OffAuth>();
    final logged = auth.isLoggedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(logged ? 'Signed in as ${auth.username}' : 'Not signed in'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: Icon(logged ? Icons.manage_accounts : Icons.login),
                  label: Text(logged ? 'Change login' : 'Sign in'),
                ),
                if (!logged)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create account'),
                  ),
                if (logged)
                  OutlinedButton.icon(
                    onPressed: auth.clear,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Credentials are stored securely on this device.'),
          ],
        ),
      ),
    );
  }
}
