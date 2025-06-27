import 'package:flutter/material.dart';

class KeyboardVisibilityDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isKeyboardVisible) builder;
  const KeyboardVisibilityDetector({Key? key, required this.builder}) : super(key: key);

  @override
  _KeyboardVisibilityDetectorState createState() => _KeyboardVisibilityDetectorState();
}

class _KeyboardVisibilityDetectorState extends State<KeyboardVisibilityDetector> with WidgetsBindingObserver {
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isKeyboardVisible);
  }
}