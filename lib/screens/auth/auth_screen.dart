import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/api_debug_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/api_debug_dialog.dart';
import 'registration_success_dialog.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginKeyController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginKeyController.dispose();
    _registerNameController.dispose();
    _registerDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.listen(authStateProvider, (prev, next) {
      if (next.registrationDetails != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RegistrationSuccessDialog(
            details: next.registrationDetails!,
            onClose: () {
              Navigator.of(context).pop();
              ref.read(authStateProvider.notifier).clearRegistrationDetails();
              context.go('/');
            },
          ),
        );
      } else if (next.agentNameTaken) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Agent name already taken'),
            content: const Text(
              'An agent with that name already exists. Please choose a different name.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) => ref.read(authStateProvider.notifier).clearAgentNameTaken());
      } else if (next.isAuthenticated && next.error == null) {
        context.go('/');
      }
    });

    return Scaffold(
      appBar: kDebugMode
          ? AppBar(
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  tooltip: 'API Debug',
                  onPressed: () {
                    final record = ref.read(apiDebugNotifierProvider).latest;
                    if (record == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No API calls recorded yet')),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => ApiDebugDialog(record: record),
                      );
                    }
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/mascot.png',
                    width: 400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'imitationCrab',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Research exoskeleton for Moltbook',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(child: SelectableText(authState.error!)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _LoginForm(
                          controller: _loginKeyController,
                          isLoading: authState.isLoading,
                          onLogin: () => ref.read(authStateProvider.notifier).login(_loginKeyController.text.trim()),
                        ),
                        _RegisterForm(
                          nameController: _registerNameController,
                          descController: _registerDescController,
                          isLoading: authState.isLoading,
                          onRegister: () => ref.read(authStateProvider.notifier).register(
                                name: _registerNameController.text.trim(),
                                description: _registerDescController.text.trim().isEmpty
                                    ? null
                                    : _registerDescController.text.trim(),
                              ),
                        ),
                      ],
                    ),
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

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.controller,
    required this.isLoading,
    required this.onLogin,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'moltbook_xxx',
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading ? null : onLogin,
            child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.nameController,
    required this.descController,
    required this.isLoading,
    required this.onRegister,
  });

  final TextEditingController nameController;
  final TextEditingController descController;
  final bool isLoading;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Agent Name',
              hintText: 'my_research_agent',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What you do',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading ? null : onRegister,
            child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
          ),
          const SizedBox(height: 16),
          Text(
            'You will receive an API key. Save it securely—it cannot be recovered.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
