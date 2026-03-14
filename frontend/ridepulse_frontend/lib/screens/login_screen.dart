import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {

      /// GoRouter navigation
      context.go('/passenger/home');

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Center(

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  /// APP ICON
                  const Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  /// APP NAME
                  const Text(
                    'Ride Pulse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Smart Digital Ticketing System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 48),

                  /// EMAIL FIELD
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,

                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),

                    validator: (value) {

                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD FIELD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,

                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    validator: (value) {

                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  /// LOGIN BUTTON
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {

                      return ElevatedButton(

                        onPressed: authProvider.isLoading
                            ? null
                            : _handleLogin,

                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),

                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  /// REGISTER BUTTON
                  TextButton(
                    onPressed: () {

                      context.push('/register');

                    },

                    child: const Text(
                      "Don't have an account? Register",
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