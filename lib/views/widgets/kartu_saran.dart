import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import '../../data/models/kategori_aqi.dart';
import 'kotak_brutal.dart';

/// Menampilkan daftar saran kesehatan sesuai kategori udara saat ini.
class KartuSaran extends StatelessWidget {
  const KartuSaran({super.key, required this.kategori});

  final KategoriAqi kategori;

  @override
  Widget build(BuildContext context) {
    return KotakBrutal(
      warna: WarnaBrutal.biru,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates),
              SizedBox(width: 8),
              Text(
                'Saran untuk Anda',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final String tip in kategori.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip, style: const TextStyle(height: 1.3)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
