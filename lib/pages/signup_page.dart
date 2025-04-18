import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:urban_route/main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  String? _errorMessage;
  bool _acceptedTerms = false;
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (Platform.isIOS) {
      // Use CupertinoDatePicker for iOS
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _dateOfBirth ?? DateTime.now(),
                    maximumDate: DateTime.now(),
                    minimumYear: 1900,
                    maximumYear: DateTime.now().year,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        _dateOfBirth = newDate;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Use Material DatePicker for Android and other platforms
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
  }

  Future<void> _selectLanguage(BuildContext context) async {
    if (Platform.isIOS) {
      // Use CupertinoPicker for iOS
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        _selectedLanguage = _languages[index]['name']!;
                      });
                    },
                    children: _languages.map((language) {
                      return Text(language['name']!);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Use Material DropdownButtonFormField for Android and other platforms
      // This is already implemented in the build method
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() {
        _errorMessage = 'Please select your date of birth';
      });
      return;
    }
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
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
          'preferred_language': _selectedLanguage,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepBlue,
              AppColors.brightCyan.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Signup Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // First Name and Last Name fields in a row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                      prefixIconColor: AppColors.deepBlue,
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your first name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                      prefixIconColor: AppColors.deepBlue,
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your last name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth field
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  prefixIconColor: AppColors.deepBlue,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  _dateOfBirth != null
                                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                      : 'Select Date',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Preferred Language dropdown
                            if (Platform.isIOS)
                              InkWell(
                                onTap: () => _selectLanguage(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Preferred Language',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.language),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  child: Text(_selectedLanguage),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Preferred Language',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.language),
                                  prefixIconColor: AppColors.deepBlue,
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                value: _selectedLanguage,
                                items: _languages.map((language) {
                                  return DropdownMenuItem<String>(
                                    value: language['name'],
                                    child: Text(language['name']!),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedLanguage = newValue;
                                    });
                                  }
                                },
                              ),
                            const SizedBox(height: 16),
                            
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email),
                                prefixIconColor: AppColors.deepBlue,
                                filled: true,
                                fillColor: Colors.grey[50],
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
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                                prefixIconColor: AppColors.deepBlue,
                                filled: true,
                                fillColor: Colors.grey[50],
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
                            const SizedBox(height: 16),
                            
                            // Confirm Password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Re-enter Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline),
                                prefixIconColor: AppColors.deepBlue,
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              obscureText: true,
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
                            
                            // Terms and Conditions checkbox
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.brightCyan,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _acceptedTerms = !_acceptedTerms;
                                        });
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms of Service',
                                              style: const TextStyle(
                                                color: AppColors.brightCyan,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' and ',
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: const TextStyle(
                                                color: AppColors.brightCyan,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Submit button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brightCyan,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
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
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Link to login page
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
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