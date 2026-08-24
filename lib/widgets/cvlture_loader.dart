import 'package:flutter/material.dart';

/// Spinner CVLTURE — logo che ruota su se stesso in senso orario
/// (da sinistra verso destra). Drop-in replacement di CircularProgressIndicator.
class CvltureLoader extends StatefulWidget {
  final double size;
  const CvltureLoader({super.key, this.size = 48});

  @override
  State<CvltureLoader> createState() => _CvltureLoaderState();
}

class _CvltureLoaderState extends State<CvltureLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    // Tween esplicito 0→1 = senso orario (da sinistra verso destra in alto)
    _turns = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turns,
      child: Image.asset(
        'assets/images/logo.png',
        width: widget.size,
        height: widget.size,
        filterQuality: FilterQuality.high,
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
