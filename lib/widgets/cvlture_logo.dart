import 'package:flutter/material.dart';

import '../main.dart';

/// Logo ufficiale CVLTURE.
///
/// Usa l'immagine in assets/images/logo.png se presente,
/// altrimenti mostra automaticamente la scritta testuale
/// "CVLTURE" come fallback (utile finché il file non viene
/// ancora caricato nel progetto, evita crash in fase di build).
class CvltureLogo extends StatelessWidget {
  /// Altezza del logo in px logici. La larghezza si adatta
  /// automaticamente mantenendo le proporzioni originali.
  final double height;

  const CvltureLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Text(
        "CVLTURE",
        style: TextStyle(
          fontSize: height * 0.62,
          fontWeight: FontWeight.w900,
          color: CvltureColors.green,
          letterSpacing: height * 0.12,
        ),
      ),
    );
  }
}
