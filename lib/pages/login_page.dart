import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers / nodes
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  // State
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _confirmationSent = false;
  String? _errorMessage;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for OAuth callback — when the user authenticates via the
    // external browser, the deep link fires an AuthState event that we
    // catch here to pop back to HomePage.
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------- Auth actions ----------

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final res =
            await _supabase.auth.signUp(email: email, password: password);
        if (!mounted) return;
        if (res.session == null) {
          // Email confirmation is required by the project's auth settings.
          setState(() {
            _confirmationSent = true;
            _isLoading = false;
          });
          return;
        }
      } else {
        await _supabase.auth
            .signInWithPassword(email: email, password: password);
      }
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
    } catch (_) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final launched = await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: _oauthRedirectUrl,
      );
      if (!mounted) return;
      if (!launched) {
        _setError('Could not open ${provider.name} sign-in. Please try again.');
      }
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
    } catch (_) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      // On web this call redirects, so state is moot; on mobile it returns
      // as soon as the browser is launched, so we must release the spinner.
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setError('Enter your email first, then tap "Forgot password?".');
      _emailFocus.requestFocus();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _oauthRedirectUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email.'),
          behavior: SnackBarBehavior.floating,
        ));
    } on AuthException catch (e) {
      _setError(_friendlyAuthError(e.message));
    } catch (_) {
      _setError('Could not send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Helpers ----------

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _confirmationSent = false;
      _obscurePassword = true;
    });
    _formKey.currentState?.reset();
  }

  void _backToSignIn() {
    setState(() {
      _isSignUp = false;
      _confirmationSent = false;
      _errorMessage = null;
    });
    _passwordController.clear();
  }

  String get _oauthRedirectUrl {
    // Web: return to the current origin. Native: use the app's URL scheme.
    if (kIsWeb) return '${Uri.base.origin}/';
    return 'io.supabase.flutter://login-callback/';
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (lower.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return message;
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _LoginHeader(isSignUp: _isSignUp),
                      const SizedBox(height: AppSpacing.xxl),
                      if (_confirmationSent)
                        _ConfirmationSentView(
                          email: _emailController.text.trim(),
                          onBack: _backToSignIn,
                        )
                      else
                        _buildForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildEmailField(),
        const SizedBox(height: AppSpacing.lg),
        _buildPasswordField(),
        if (!_isSignUp) _buildForgotPasswordLink(),
        const SizedBox(height: AppSpacing.lg),
        _buildPrimaryButton(),
        const SizedBox(height: AppSpacing.lg),
        const _DividerLabel(label: 'Or continue with'),
        const SizedBox(height: AppSpacing.lg),
        _buildOAuthButtons(),
        const SizedBox(height: AppSpacing.xl),
        if (_isSignUp) ...[
          const _TermsNote(),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildAuthToggle(),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      enabled: !_isLoading,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email, AutofillHints.username],
      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Please enter your email';
        if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: [
        _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: _isSignUp ? 'At least 8 characters' : 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: _isLoading
              ? null
              : () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (_isSignUp && value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading ? null : _sendPasswordReset,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Forgot password?'),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _submit,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_isSignUp ? 'Create Account' : 'Sign In'),
    );
  }

  Widget _buildOAuthButtons() {
    return Column(
      children: [
        _OAuthButton(
          label: 'Continue with Google',
          icon: const _GoogleIcon(),
          onPressed: _isLoading
              ? null
              : () => _signInWithOAuth(OAuthProvider.google),
        ),
        const SizedBox(height: AppSpacing.md),
        _OAuthButton(
          label: 'Continue with GitHub',
          icon: const _GitHubIcon(),
          onPressed: _isLoading
              ? null
              : () => _signInWithOAuth(OAuthProvider.github),
        ),
      ],
    );
  }

  Widget _buildAuthToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account?' : "Don't have an account?",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _isLoading ? null : _toggleAuthMode,
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.isSignUp});
  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(
            Icons.task_alt_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'TaskNest',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isSignUp ? 'Create your account' : 'Welcome back',
            key: ValueKey(isSignUp),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'By creating an account you agree to our Terms of Service '
      'and Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ConfirmationSentView extends StatelessWidget {
  const _ConfirmationSentView({required this.email, required this.onBack});
  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Check your inbox',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a confirmation link to\n$email\n\nTap the link to activate '
          'your account, then come back and sign in.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: onBack,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.g_mobiledata, size: 22);
}

class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();
  @override
  Widget build(BuildContext context) => const Icon(Icons.code, size: 20);
}