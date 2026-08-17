import 'package:flutter/material.dart';

/// Spinner di caricamento con il logo CVLTURE che ruota su se stesso.
/// Drop-in replacement di CircularProgressIndicator.
///
/// Uso rapido:
///   const CvltureLoader()           // 48px, versione standard
///   const CvltureLoader(size: 28)   // inline nei bottoni
///   const CvltureLoader(size: 72)   // fullscreen
class CvltureLoader extends StatefulWidget {
  final double size;

  const CvltureLoader({super.key, this.size = 48});

  @override
  State<CvltureLoader> createState() => _CvltureLoaderState();
}

class _CvltureLoaderState extends State<CvltureLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Image.asset(
        'assets/images/logo.png',
        width: widget.size,
        height: widget.size,
        filterQuality: FilterQuality.high,
        // Fallback testo se il file non è presente
        errorBuilder: (_, __, ___) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: const Color(0xFF00FF49),
          ),
        ),
      ),
    );
  }
}
