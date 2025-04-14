import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null && _isSignUp) {
      setState(() {
        _errorMessage = 'Please select your date of birth';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (res.user != null) {
        // Insert additional user data into the Users table
        await Supabase.instance.client.from('Users').insert({
          'id': res.user!.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'date_of_birth': _dateOfBirth?.toIso8601String(),
          'email': _emailController.text.trim(),
        });

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = 'Sign up failed. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, check if the user exists
      final List<dynamic> users = await Supabase.instance.client
          .from('Users')
          .select()
          .eq('email', _emailController.text.trim());

      if (users.isEmpty) {
        setState(() {
          _errorMessage = 'No user found with this email';
          _isLoading = false;
        });
        return;
      }

      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (res.user != null) {
        // Update last_logged_in
        await Supabase.instance.client
            .from('Users')
            .update({'last_logged_in': DateTime.now().toIso8601String()})
            .eq('id', res.user!.id);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = 'Sign in failed. Please check your credentials.';
        });
      }
    } on AuthException catch (error) {
      setState(() {
        // Provide more specific error messages based on the error code
        switch (error.statusCode) {
          case '400':
            _errorMessage = 'Invalid credentials. Please check your email and password.';
            break;
          case '401':
            _errorMessage = 'Please verify your email before signing in.';
            break;
          case '422':
            _errorMessage = 'Invalid email format.';
            break;
          default:
            _errorMessage = 'Error: ${error.message}';
        }
      });
      print('Auth Error: ${error.message}'); // For debugging
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $error';
      });
      print('General Error: $error'); // For debugging
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or App Name
                  const Icon(
                    Icons.map,
                    size: 80,
                    color: Color(0xFF1F8DED),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Urban Route',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF1F8DED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Toggle between Sign In and Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = false),
                        style: TextButton.styleFrom(
                          foregroundColor: _isSignUp ? Colors.grey : const Color(0xFF1F8DED),
                        ),
                        child: const Text('Sign In'),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = true),
                        style: TextButton.styleFrom(
                          foregroundColor: _isSignUp ? const Color(0xFF1F8DED) : Colors.grey,
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign Up Fields
                  if (_isSignUp) ...[
                    // First Name field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth field
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
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
                  
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F8DED),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
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