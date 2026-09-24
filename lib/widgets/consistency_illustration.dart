import 'package:flutter/material.dart';
import '../models/consistency.dart';

/// The adjacent text supplies the accessible category label.
class ConsistencyIllustration extends StatelessWidget {
  final Consistency consistency;
  final double size;

  const ConsistencyIllustration({
    super.key,
    required this.consistency,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) => Image.asset(
        consistency.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
}
