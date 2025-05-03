import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_route/main.dart';
import 'package:urban_route/schema/database_schema.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, check if the user exists and is active
      final user = await Supabase.instance.client
          .from(DatabaseSchema.users)
          .select()
          .eq(Users.email, _emailController.text.trim())
          .eq(Users.isActive, true)
          .single();

      if (user == null) {
        setState(() {
          _errorMessage = 'No active user found with this email';
          _isLoading = false;
        });
        return;
      }

      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (res.user != null) {
        await Supabase.instance.client
            .from(DatabaseSchema.users)
            .update(DatabaseSchema.updateLastLogin())
            .eq(Users.id, res.user!.id);
            

        if (user[Users.preferredLanguage] != null) {
          // to do: make this a map or something more efficient
          String dbLanguage = user[Users.preferredLanguage].toString().toLowerCase();
          String languageCode;
          
          if (dbLanguage.contains('es') || 
              dbLanguage == 'Español') {
            languageCode = 'es';
          } else {
            // default to english
            languageCode = 'en';
          }
          
          // update the locale
          _saveUserLanguagePreference(languageCode);
        }

        // here is where I need

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
    
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _saveUserLanguagePreference(String languageCode) async {
    try {
      // to do: make this a map or something more efficient
      if (!['en', 'es'].contains(languageCode)) {
        languageCode = 'en'; // default to english
      }
      
      // update the app locale
      context.setLocale(Locale(languageCode));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    } catch (e) {
      print('Error setting language preference: $e');
      // Default to English in case of error
      context.setLocale(const Locale('en'));
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
                    // Logo and App Name
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/UrbanRoute_logo.png',
                            height: 150,
                            width: 150,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Login Form
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
                            Text(
                              'auth.welcome_back'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'auth.email'.tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email),
                                prefixIconColor: AppColors.brightCyan,
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
                                labelText: 'auth.password'.tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                                prefixIconColor: AppColors.brightCyan,
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
                            const SizedBox(height: 24),
                            
                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
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
                              onPressed: _isLoading ? null : _signIn,
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
                                  : Text(
                                      'auth.sign_in'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 16),
                            
                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('auth.no_account'.tr()),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/signup');
                                  },
                                  child: Text(
                                    'auth.sign_up'.tr(),
                                    style: TextStyle(
                                      color: AppColors.brightCyan,  
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),  
                            
                            // Language selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${context.locale.languageCode == 'en' ? 'Language' : 'Idioma'}: '),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: context.locale.languageCode,
                                  underline: Container(
                                    height: 2,
                                    color: AppColors.brightCyan,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Text(
                                        'English',
                                        style: TextStyle(
                                          fontWeight: context.locale.languageCode == 'en'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'es',
                                      child: Text(
                                        'Español',
                                        style: TextStyle(
                                          fontWeight: context.locale.languageCode == 'es'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _saveUserLanguagePreference(newValue);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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