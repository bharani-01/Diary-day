import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../constants.dart';
import '../services/language_provider.dart';
import 'main_navigation_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _otpSent = false;
  int _countdown = 0;
  Timer? _timer;
  bool _agreeToPolicies = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Reset OTP state when switching tabs
        setState(() {
          _otpSent = false;
          _otpController.clear();
          _countdown = 0;
          _timer?.cancel();
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String? _validateEmail(String? val, LanguageProvider lp) {
    if (val == null || val.trim().isEmpty) {
      return lp.translate('err_invalid_email');
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(val.trim())) {
      return lp.translate('err_invalid_email');
    }
    return null;
  }

  String? _validatePassword(String? val, LanguageProvider lp) {
    if (_tabController.index == 0) {
      if (val == null || val.isEmpty || val.length < 6) {
        return lp.translate('err_invalid_password');
      }
    }
    return null;
  }

  String? _validateOtp(String? val, LanguageProvider lp) {
    if (_tabController.index == 1 && _otpSent) {
      if (val == null || val.trim().length != 6 || int.tryParse(val.trim()) == null) {
        return lp.translate('err_invalid_otp');
      }
    }
    return null;
  }

  Future<void> _handlePasswordLogin(LanguageProvider lp) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (response.user != null) {
        if (mounted) {
          _showSuccessSnackBar(lp.isTamil ? 'வெற்றிகரமாக உள்நுழைந்தீர்கள்!' : 'Logged in successfully!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOTP(LanguageProvider lp) async {
    if (!_emailController.text.isNotEmpty || _validateEmail(_emailController.text, lp) != null) {
      _showErrorSnackBar(lp.translate('err_invalid_email'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: false, // Handled manually
      );
      
      setState(() {
        _otpSent = true;
      });
      _startCountdown();
      _showSuccessSnackBar(
        lp.isTamil 
            ? 'OTP குறியீடு ${_emailController.text.trim()} முகவரிக்கு அனுப்பப்பட்டது!' 
            : 'OTP sent to ${_emailController.text.trim()}!'
      );
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP(LanguageProvider lp) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.user != null) {
        if (mounted) {
          _showSuccessSnackBar(lp.isTamil ? 'வெற்றிகரமாக உள்நுழைந்தீர்கள்!' : 'Logged in successfully!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient and abstract shapes
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                      : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB), const Color(0xFF80CBC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Abstract floating light/green shapes for premium effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primaryColor.withOpacity(isDark ? 0.2 : 0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.secondaryColor.withOpacity(isDark ? 0.1 : 0.3),
              ),
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Switcher & App Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            lp.toggleLanguage();
                          },
                          icon: const Icon(Icons.translate, size: 16, color: AppConstants.primaryColor),
                          label: Text(
                            lp.isTamil ? 'English' : 'தமிழ்',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // App Logo
                    Image.asset(
                      'assets/logo.png',
                      width: 130,
                      height: 130,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            size: 70,
                            color: AppConstants.primaryColor,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand Title
                    Text(
                      lp.translate('login_title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isDark ? Colors.white : AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lp.translate('login_subtitle'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Glassmorphic Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.45 : 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Tab Bar Selector
                                  Container(
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: TabBar(
                                      controller: _tabController,
                                      indicator: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppConstants.primaryColor,
                                      ),
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      labelColor: Colors.white,
                                      unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
                                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      tabs: [
                                        Tab(text: lp.translate('tab_password')),
                                        Tab(text: lp.translate('tab_otp')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Email Input (Shared)
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    enabled: !_isLoading && !_otpSent,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                    decoration: AppConstants.inputDecoration(
                                      lp.translate('email_label'),
                                      context,
                                    ).copyWith(
                                      prefixIcon: const Icon(Icons.email_outlined, color: AppConstants.primaryColor),
                                    ),
                                    validator: (val) => _validateEmail(val, lp),
                                  ),
                                  const SizedBox(height: 16),

                                  // Conditional fields based on selected tab
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    child: _tabController.index == 0
                                        ? _buildPasswordFields(lp, isDark)
                                        : _buildOtpFields(lp, isDark),
                                  ),
                                  
                                  const SizedBox(height: 24),

                                  // Checkbox Agreement Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _agreeToPolicies,
                                          activeColor: AppConstants.primaryColor,
                                          onChanged: (val) {
                                            setState(() {
                                              _agreeToPolicies = val ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.black87,
                                              fontSize: 12,
                                              fontFamily: 'Work Sans',
                                              height: 1.4,
                                            ),
                                            children: [
                                              TextSpan(text: lp.translate('agree_to_policies_prefix')),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.baseline,
                                                baseline: TextBaseline.alphabetic,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                                                    );
                                                  },
                                                  child: Text(
                                                    lp.translate('terms_conditions'),
                                                    style: const TextStyle(
                                                      color: AppConstants.primaryColor,
                                                      fontWeight: FontWeight.bold,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextSpan(text: lp.translate('agree_and')),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.baseline,
                                                baseline: TextBaseline.alphabetic,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                                                    );
                                                  },
                                                  child: Text(
                                                    lp.translate('privacy_policy'),
                                                    style: const TextStyle(
                                                      color: AppConstants.primaryColor,
                                                      fontWeight: FontWeight.bold,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextSpan(text: lp.translate('agree_to_policies_suffix')),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  _isLoading
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8.0),
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _agreeToPolicies
                                              ? () {
                                                  if (_tabController.index == 0) {
                                                    _handlePasswordLogin(lp);
                                                  } else {
                                                    if (_otpSent) {
                                                      _handleVerifyOTP(lp);
                                                    } else {
                                                      _handleSendOTP(lp);
                                                    }
                                                  }
                                                }
                                              : () {
                                                  _showErrorSnackBar(lp.translate('agree_err'));
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _agreeToPolicies
                                                ? AppConstants.primaryColor
                                                : AppConstants.primaryColor.withOpacity(0.5),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            _tabController.index == 0
                                                ? lp.translate('btn_signin')
                                                : (_otpSent 
                                                    ? lp.translate('btn_verify_otp') 
                                                    : lp.translate('btn_send_otp')),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
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

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFields(LanguageProvider lp, bool isDark) {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      enabled: !_isLoading,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: AppConstants.inputDecoration(
        lp.translate('password_label'),
        context,
      ).copyWith(
        prefixIcon: const Icon(Icons.lock_outline, color: AppConstants.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppConstants.primaryColor,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: (val) => _validatePassword(val, lp),
    );
  }

  Widget _buildOtpFields(LanguageProvider lp, bool isDark) {
    if (!_otpSent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          maxLength: 6,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: AppConstants.inputDecoration(
            lp.translate('otp_label'),
            context,
          ).copyWith(
            prefixIcon: const Icon(Icons.security, color: AppConstants.primaryColor),
            counterText: '',
          ),
          validator: (val) => _validateOtp(val, lp),
        ),
        const SizedBox(height: 12),
        
        // Countdown text & Resend button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                // Return to step 1 (change email / edit email)
                setState(() {
                  _otpSent = false;
                  _otpController.clear();
                  _countdown = 0;
                  _timer?.cancel();
                });
              },
              child: Text(
                lp.isTamil ? 'மின்னஞ்சலை மாற்று' : 'Edit Email',
                style: const TextStyle(fontSize: 12, color: AppConstants.primaryColor),
              ),
            ),
            _countdown > 0
                ? Text(
                    lp.translate('btn_resend_countdown').replaceAll('{seconds}', _countdown.toString()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )
                : TextButton(
                    onPressed: _isLoading ? null : () => _handleSendOTP(lp),
                    child: Text(
                      lp.translate('btn_resend_otp'),
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
