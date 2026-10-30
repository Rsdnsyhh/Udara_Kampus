import 'package:flutter/material.dart';

/// Memunculkan widget dengan gerakan naik sambil memudar masuk.
/// Nilai [urutan] menambah lama animasi sehingga kartu-kartu tampil
/// berurutan dari atas ke bawah.
class MunculBertahap extends StatelessWidget {
  const MunculBertahap({super.key, required this.urutan, required this.child});

  final int urutan;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + urutan * 90),
      // Kurva tanpa pantulan dipilih karena nilai opacity harus tetap
      // berada di rentang 0 sampai 1.
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double nilai, Widget? anak) {
        return Opacity(
          opacity: nilai,
          child: Transform.translate(
            offset: Offset(0, (1 - nilai) * 24),
            child: anak,
          ),
        );
      },
      child: child,
    );
  }
}
