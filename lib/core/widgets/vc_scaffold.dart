import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              automaticallyImplyLeading: false,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/submissions');
                        }
                      },
                    )
                  : null,
              actions: actions,
            )
          : null,
      body: SafeArea(child: body),
    );
  }
}
