import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'PASSENGER';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _roles = [
    'PASSENGER',
    'DRIVER',
    'CONDUCTOR',
    'BUS_OWNER',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      /// GoRouter navigation
      context.go('/login');

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Register'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                const Icon(
                  Icons.person_add,
                  size: 60,
                  color: Colors.blue,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                /// FULL NAME
                TextFormField(
                  controller: _fullNameController,

                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {

                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }

                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// EMAIL
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

                /// PHONE
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,

                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {

                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }

                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// ROLE
                DropdownButtonFormField<String>(

                  value: _selectedRole,

                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),

                  items: _roles.map((role) {

                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );

                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// PASSWORD
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
                      return 'Please enter a password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// CONFIRM PASSWORD
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,

                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),

                  validator: (value) {

                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }

                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// REGISTER BUTTON
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {

                    return ElevatedButton(

                      onPressed: authProvider.isLoading
                          ? null
                          : _handleRegister,

                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                              'Register',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                /// LOGIN LINK
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text(
                    'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}