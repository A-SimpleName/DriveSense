import 'dart:async';

import 'package:flutter/material.dart';

class DelayedConfirmDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final int delaySeconds;
  final Color? confirmButtonColor;

  const DelayedConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Bestätigen',
    this.cancelText = 'Abbrechen',
    this.delaySeconds = 5,
    this.confirmButtonColor,
  });

  @override
  State<DelayedConfirmDialog> createState() =>
      _DelayedConfirmDialogState();
}

class _DelayedConfirmDialogState extends State<DelayedConfirmDialog> {
  Timer? _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();

    _secondsRemaining = widget.delaySeconds;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_secondsRemaining <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() => _secondsRemaining = 0);
          }

          return;
        }

        if (mounted) {
          setState(() => _secondsRemaining--);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = _secondsRemaining == 0;

    return AlertDialog(
      title: Text(widget.title),
      content: Text(widget.content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: isUnlocked
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmButtonColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isUnlocked
                ? widget.confirmText
                : '${widget.confirmText} ($_secondsRemaining)',
          ),
        ),
      ],
    );
  }
}
