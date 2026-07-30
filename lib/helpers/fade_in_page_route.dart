import 'package:flutter/material.dart';
class FadeInPageRoute extends PageRouteBuilder {
  final Widget page;

  FadeInPageRoute({required this.page})
      : super(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
