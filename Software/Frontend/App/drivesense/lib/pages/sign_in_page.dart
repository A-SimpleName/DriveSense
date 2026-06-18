import 'package:drivesense/config/app_colors.dart';
import 'package:drivesense/pages/forgot_password_page.dart';
import 'package:drivesense/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:drivesense/services/sign_in_and_sign_up.dart';
import 'package:drivesense/services/deep_link_service.dart';

class SignInPage extends StatefulWidget {
  final bool? token;

  const SignInPage({super.key, this.token});

  @override
  State<StatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCredentialError = false;
  String? _errorTitle;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsAuthScaffold(
      title: 'Anmelden',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _errorMessage == null
                  ? const SizedBox.shrink()
                  : _SignInErrorBanner(
                      key: ValueKey<String>(_errorMessage!),
                      title: _errorTitle ?? 'Anmeldung fehlgeschlagen',
                      message: _errorMessage!,
                      showResetAction: _isCredentialError,
                      onDismiss: _clearError,
                      onResetPassword: _openForgotPassword,
                    ),
            ),
            if (_errorMessage != null) const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              onChanged: (_) => _clearError(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-Mail Adresse',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              onChanged: (_) => _clearError(),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                _submitSignIn();
              },
              decoration: InputDecoration(
                labelText: 'Passwort',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Anmelden'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _openForgotPassword,
              child: const Text('Passwort vergessen?'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sie haben noch keinen Account?',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, 'SignUpPage');
              },
              child: const Text('Jetzt Registrieren'),
            ),
          ],
        ),
      ),
    );
  }

  /// Validates local input, calls the auth service, and renders failures inline
  /// so the user can still see what went wrong after the snackbar would vanish.
  Future<void> _submitSignIn() async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String emailValue = _emailController.text.trim();
    final String passwordValue = _passwordController.text.trim();

    if (emailValue.isEmpty || passwordValue.isEmpty) {
      _showInlineError(
        title: 'Eingaben fehlen',
        message: 'Bitte E-Mail und Passwort eingeben.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _clearErrorState();
    });

    try {
      final SignInResult result = await SignInAndSignUp.signIn(
        emailValue,
        passwordValue,
      );

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        final bool handledPendingInvite =
            await DeepLinkService.processPendingInvite();
        if (handledPendingInvite) {
          return;
        }
        if (!mounted) {
          return;
        }

        // Success keeps the existing flow: show a short confirmation and move
        // into profile selection/main routing based on the returned token.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        Navigator.pushNamedAndRemoveUntil(
          context,
          SignInAndSignUp.redirectToProfileSelectPage(
            token: result.accountToken,
          ),
          (route) => false,
        );
        return;
      }

      // Credential errors get a stronger inline treatment because the next
      // useful action is often resetting the password.
      _showInlineError(
        title: result.isCredentialError
            ? 'E-Mail oder Passwort passt nicht'
            : 'Login nicht möglich',
        message: result.message,
        credentialError: result.isCredentialError,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showInlineError(
        title: 'Login nicht möglich',
        message: 'Fehler bei der Anmeldung. Bitte versuchen Sie es erneut.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Opens the existing reset flow from both the text link and the error banner.
  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ForgotPasswordPage(),
      ),
    );
  }

  /// Stores the visible error state. The fields clear as soon as the user edits
  /// either credential field.
  void _showInlineError({
    required String title,
    required String message,
    bool credentialError = false,
  }) {
    setState(() {
      _errorTitle = title;
      _errorMessage = message;
      _isCredentialError = credentialError;
    });
  }

  void _clearError() {
    if (_errorMessage == null) {
      return;
    }

    setState(_clearErrorState);
  }

  void _clearErrorState() {
    _errorTitle = null;
    _errorMessage = null;
    _isCredentialError = false;
  }
}

/// Compact inline error shown above the sign-in fields.
///
/// This is intentionally persistent and dismissible, unlike a snackbar, so
/// invalid-credential feedback remains visible while the user fixes input.
class _SignInErrorBanner extends StatelessWidget {
  final String title;
  final String message;
  final bool showResetAction;
  final VoidCallback onDismiss;
  final VoidCallback onResetPassword;

  const _SignInErrorBanner({
    super.key,
    required this.title,
    required this.message,
    required this.showResetAction,
    required this.onDismiss,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                  if (showResetAction) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onResetPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onErrorContainer,
                        ),
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Passwort zurücksetzen'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Meldung schliessen',
              onPressed: onDismiss,
              color: colors.onErrorContainer,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
