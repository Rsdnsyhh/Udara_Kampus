import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import '../../core/utils/format.dart';
import '../../data/models/udara.dart';
import 'kotak_brutal.dart';

/// Menyusun kartu polutan dalam dua kolom.
class GrafikPolutan extends StatelessWidget {
  const GrafikPolutan({super.key, required this.daftar});

  final List<Polutan> daftar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        const double jarak = 14;
        // Lebar satu kartu dihitung dari lebar yang tersedia. Selisih 5
        // piksel disisakan agar bayangan kartu tidak terpotong.
        final double lebar = (batas.maxWidth - jarak - 5) / 2;
        return Wrap(
          spacing: jarak,
          runSpacing: jarak,
          children: [
            for (final Polutan p in daftar)
              SizedBox(width: lebar, child: KartuPolutan(polutan: p)),
          ],
        );
      },
    );
  }
}

/// Kartu satu polutan: simbol, status, kadar, dan batang perbandingan
/// terhadap batas pedoman WHO.
class KartuPolutan extends StatelessWidget {
  const KartuPolutan({super.key, required this.polutan});

  final Polutan polutan;

  /// Menentukan label dan warna status dari rasio kadar terhadap batas.
  /// Kadar kosong diberi status "N/A" agar tidak terbaca sebagai aman.
  ({String label, Color warna}) _status(double? rasio) {
    if (rasio == null) return (label: 'N/A', warna: Colors.grey.shade300);
    if (rasio <= 1) return (label: 'AMAN', warna: WarnaBrutal.hijau);
    if (rasio <= 2) return (label: 'WASPADA', warna: WarnaBrutal.kuning);
    return (label: 'TINGGI', warna: const Color(0xFFFF7A7A));
  }

  @override
  Widget build(BuildContext context) {
    final double? rasio = polutan.rasio;
    final status = _status(rasio);
    // Batang penuh bila kadar mencapai 3 kali batas pedoman. Nilai minimum
    // 0,04 menjaga batang tetap terlihat walaupun kadarnya sangat kecil.
    final double isi = rasio == null ? 0 : (rasio / 3).clamp(0.04, 1.0);

    return KotakBrutal(
      padding: const EdgeInsets.all(12),
      radius: 14,
      bayangan: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                polutan.simbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.warna,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WarnaBrutal.garis, width: 1.5),
                ),
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Text(
            polutan.nama,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAngka(polutan.nilai),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' ${polutan.satuan}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: WarnaBrutal.garis, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isi),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double nilai, Widget? _) {
                return FractionallySizedBox(
                  widthFactor: nilai,
                  child: Container(color: status.warna),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
