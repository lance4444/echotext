import 'package:flutter/material.dart';

class StyledButton extends StatelessWidget {
  const StyledButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final void Function() onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color.fromARGB(255, 15, 14, 14),
                const Color.fromARGB(255, 241, 54, 185)
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.all(Radius.circular(90)),
            ),
            child: child));
  }
}
