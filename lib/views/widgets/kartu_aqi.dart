import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import '../../data/models/kategori_aqi.dart';
import '../../data/models/udara.dart';
import 'kotak_brutal.dart';

/// Kartu utama: nilai AQI, kategori, ikon ekspresi, saran singkat, dan
/// skala warna. Warna kartu mengikuti kategori udara.
class KartuAqi extends StatelessWidget {
  const KartuAqi({super.key, required this.udara});

  final Udara udara;

  @override
  Widget build(BuildContext context) {
    final UdaraSaatIni saatIni = udara.saatIni;
    final KategoriAqi kategori = saatIni.kategori;

    return KotakBrutal(
      warna: kategori.warna,
      padding: const EdgeInsets.all(20),
      radius: 24,
      bayangan: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WarnaBrutal.garis, width: 2),
                ),
                child: const Text(
                  'US AQI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                udara.kota.nama.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // TweenAnimationBuilder menganimasikan angka dari nilai
              // sebelumnya ke nilai baru setiap kali data berubah.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: saatIni.aqi.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double nilai, Widget? _) {
                  return Text(
                    nilai.round().toString(),
                    style: const TextStyle(
                      fontSize: 88,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
              const Spacer(),
              // Key berdasarkan kategori membuat ikon beranimasi hanya
              // ketika kategorinya berganti, bukan pada setiap pembaruan.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget anak, Animation<double> animasi) =>
                    ScaleTransition(scale: animasi, child: anak),
                child: Icon(
                  kategori.ikon,
                  key: ValueKey(kategori),
                  size: 76,
                  semanticLabel: kategori.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kategori.label.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            kategori.saran,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 18),
          MeterAqi(aqi: saatIni.aqi),
        ],
      ),
    );
  }
}

/// Batang skala enam warna dengan penunjuk yang bergeser sesuai nilai AQI.
class MeterAqi extends StatelessWidget {
  const MeterAqi({super.key, required this.aqi});

  final int aqi;

  // Lebar tiap segmen sebanding dengan rentang kategorinya (0-50, 51-100,
  // dan seterusnya). Dua segmen terakhir dibuat lebih lebar agar skala
  // tetap mencakup nilai hingga 400.
  static const List<int> _lebar = [50, 50, 50, 50, 100, 100];
  static const int _total = 400;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints batas) {
        final double lebar = batas.maxWidth;
        // clamp menjaga penunjuk tetap di dalam batang walaupun AQI
        // melebihi skala.
        final double posisi = (aqi.clamp(0, _total) / _total) * lebar;

        return SizedBox(
          height: 48,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 26,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: WarnaBrutal.garis, width: 2.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      for (int i = 0; i < _lebar.length; i++)
                        Expanded(
                          flex: _lebar[i],
                          child: Container(color: KategoriAqi.values[i].warna),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                left: posisi - 16, // 16 = setengah lebar ikon penunjuk
                top: 0,
                child: const Icon(Icons.arrow_drop_down, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}
