import 'package:flutter/material.dart';

class VerificationCodeDialog extends StatefulWidget {
  final String title;
  final String description;
  final String submitLabel;
  final String? resendLabel;
  final Future<String?> Function(String code) onSubmit;
  final Future<String?> Function()? onResend;
  final bool collectOnly;

  const VerificationCodeDialog({
    super.key,
    required this.title,
    required this.description,
    required this.submitLabel,
    required this.onSubmit,
    this.resendLabel,
    this.onResend,
    this.collectOnly = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    required String submitLabel,
    required Future<String?> Function(String code) onSubmit,
    String? resendLabel,
    Future<String?> Function()? onResend,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => VerificationCodeDialog(
        title: title,
        description: description,
        submitLabel: submitLabel,
        onSubmit: onSubmit,
        resendLabel: resendLabel,
        onResend: onResend,
      ),
    );
  }

  static Future<String?> collect({
    required BuildContext context,
    required String title,
    required String description,
    required String submitLabel,
    String? resendLabel,
    Future<String?> Function()? onResend,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => VerificationCodeDialog(
        title: title,
        description: description,
        submitLabel: submitLabel,
        onSubmit: (String code) async => code,
        resendLabel: resendLabel,
        onResend: onResend,
        collectOnly: true,
      ),
    );
  }

  @override
  State<VerificationCodeDialog> createState() => _VerificationCodeDialogState();
}

class _VerificationCodeDialogState extends State<VerificationCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final String code = _codeController.text.trim();

    if (widget.collectOnly) {
      Navigator.of(context).pop(code);
      return;
    }

    final String? errorMessage = await widget.onSubmit(code);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (errorMessage == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _errorText = errorMessage);
  }

  Future<void> _resend() async {
    final Future<String?> Function()? onResend = widget.onResend;
    if (onResend == null || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorText = null;
    });

    final String? errorMessage = await onResend();

    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code wurde erneut gesendet.')),
      );
      return;
    }

    setState(() => _errorText = errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.description),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Bestätigungscode',
                hintText: '123456',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                final String code = value?.trim() ?? '';
                if (code.isEmpty) {
                  return 'Bitte den Code eingeben';
                }
                if (code.length != 6) {
                  return 'Der Code muss 6 Stellen haben';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting || _isResending
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        if (widget.onResend != null)
          TextButton(
            onPressed: _isSubmitting || _isResending ? null : _resend,
            child: _isResending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.resendLabel ?? 'Code erneut senden'),
          ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}
