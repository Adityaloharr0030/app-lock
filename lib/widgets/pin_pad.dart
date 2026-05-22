import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  final Function(String) onPinEntered;
  final VoidCallback onBackspace;
  final VoidCallback? onForgotPin;

  const PinPad({
    super.key,
    required this.onPinEntered,
    required this.onBackspace,
    this.onForgotPin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row in [[1, 2, 3], [4, 5, 6], [7, 8, 9]])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((n) => _buildButton(context, n.toString())).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            onForgotPin != null 
              ? TextButton(onPressed: onForgotPin, child: const Text('Forgot?'))
              : const SizedBox(width: 64),
            _buildButton(context, '0'),
            IconButton(
              onPressed: onBackspace,
              icon: const Icon(Icons.backspace_outlined),
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => onPinEntered(text),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
