import 'package:flutter/material.dart';

/// Menggambar pola titik-titik tipis sebagai latar halaman agar tidak polos.
/// Pola digambar langsung di kanvas, sehingga tidak memerlukan berkas gambar.
class LatarTitik extends CustomPainter {
  const LatarTitik();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint kuas = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.12);
    // Titik disusun dalam kisi dengan jarak 24 piksel.
    for (double x = 12; x < size.width; x += 24) {
      for (double y = 12; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1.6, kuas);
      }
    }
  }

  // Pola tidak pernah berubah, jadi tidak perlu digambar ulang.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
