import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final ValueChanged<UserProfile> onLogin;

  const LoginScreen({
    super.key,
    required this.api,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool busy = false;
  String? error;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final phoneNumber = phoneController.text.trim();
    final password = passwordController.text;

    if (phoneNumber.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Enter your phone number and password.';
      });
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final result = await widget.api.login(
        phoneNumber: phoneNumber,
        password: password,
        deviceName: 'smartpay-customer-app',
      );

      if (!mounted) return;

      if (result.mustChangePassword) {
        final changedUser = await showDialog<UserProfile>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _ChangePasswordDialog(
            api: widget.api,
            currentPassword: password,
          ),
        );

        if (changedUser == null) {
          await widget.api.logout();
          if (!mounted) return;
          setState(() {
            error = 'You must change the temporary PIN before continuing.';
          });
          return;
        }

        widget.onLogin(changedUser);
        return;
      }

      widget.onLogin(result.user);
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/smartpay_logo.png',
                    height: 96,
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SmartPay',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your phone loan with confidence.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: phoneController,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: ' e.g. 0700123456',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    enabled: !busy,
                    obscureText: true,
                    onSubmitted: (_) => submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password or temporary PIN',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.login),
                    label: Text(busy ? 'Signing in...' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final ApiClient api;
  final String currentPassword;

  const _ChangePasswordDialog({
    required this.api,
    required this.currentPassword,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final newPasswordController = TextEditingController();
  final confirmationController = TextEditingController();

  bool busy = false;
  String? error;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final newPassword = newPasswordController.text;
    final confirmation = confirmationController.text;

    if (newPassword.length < 8) {
      setState(() {
        error = 'Your new password must be at least 8 characters.';
      });
      return;
    }

    if (newPassword != confirmation) {
      setState(() {
        error = 'The two new passwords do not match.';
      });
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final user = await widget.api.changePassword(
        currentPassword: widget.currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;
      Navigator.of(context).pop(user);
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.toString();
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set your private password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your account is using the temporary PIN 1234. You must replace it before viewing your loan.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              enabled: !busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New private password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmationController,
              enabled: !busy,
              obscureText: true,
              onSubmitted: (_) => changePassword(),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Sign out'),
        ),
        FilledButton(
          onPressed: busy ? null : changePassword,
          child: Text(busy ? 'Saving...' : 'Save password'),
        ),
      ],
    );
  }
}
