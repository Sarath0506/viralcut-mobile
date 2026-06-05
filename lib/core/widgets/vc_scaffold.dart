import 'package:flutter/material.dart';

class VcScaffold extends StatelessWidget {
  const VcScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.showBack = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              automaticallyImplyLeading: showBack,
              actions: actions,
            )
          : null,
      body: SafeArea(child: body),
    );
  }
}
