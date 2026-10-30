import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';

/// Wadah dasar bergaya neo-brutalism: garis tebal dan bayangan keras
/// (tanpa blur). Hampir semua kartu di aplikasi ini memakai widget ini
/// agar tampilannya seragam.
class KotakBrutal extends StatelessWidget {
  const KotakBrutal({
    super.key,
    required this.child,
    this.warna = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.bayangan = 5,
  });

  final Widget child;
  final Color warna;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Jarak geser bayangan ke kanan dan ke bawah (dalam piksel).
  final double bayangan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WarnaBrutal.garis, width: 3),
        boxShadow: [
          BoxShadow(
            color: WarnaBrutal.garis,
            offset: Offset(bayangan, bayangan),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tombol berbentuk pil yang tampak "tenggelam" saat ditekan atau dipilih.
/// Efeknya dibuat dengan menggeser tombol ke arah bayangan sambil
/// mengecilkan bayangannya.
class TombolBrutal extends StatefulWidget {
  const TombolBrutal({
    super.key,
    required this.label,
    required this.onTap,
    this.terpilih = false,
    this.warna = WarnaBrutal.kuning,
    this.ikon,
  });

  final String label;
  final VoidCallback onTap;
  final bool terpilih;

  /// Warna isi tombol ketika sedang terpilih.
  final Color warna;
  final IconData? ikon;

  @override
  State<TombolBrutal> createState() => _TombolBrutalState();
}

class _TombolBrutalState extends State<TombolBrutal> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    final bool turun = _ditekan || widget.terpilih;
    final double geser = turun ? 3 : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _ditekan = true),
      onTapUp: (_) => setState(() => _ditekan = false),
      onTapCancel: () => setState(() => _ditekan = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        // Margin dan bayangan berubah berlawanan sehingga ukuran total
        // tombol tetap, dan tombol lain di sekitarnya tidak ikut bergeser.
        margin: EdgeInsets.only(
          left: geser,
          top: geser,
          right: 3 - geser,
          bottom: 3 - geser,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.terpilih ? widget.warna : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: WarnaBrutal.garis, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: WarnaBrutal.garis,
              offset: Offset(3 - geser, 3 - geser),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.ikon != null) ...[
              Icon(widget.ikon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
