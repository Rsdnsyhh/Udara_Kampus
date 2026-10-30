import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import '../../core/utils/format.dart';
import '../../data/models/udara.dart';
import 'kotak_brutal.dart';

/// Grafik batang AQI per jam untuk 24 jam ke depan. Pengguna dapat
/// mengetuk sebuah batang untuk melihat rincian jam tersebut.
class GrafikJam extends StatefulWidget {
  const GrafikJam({super.key, required this.data});

  final List<PrakiraanJam> data;

  @override
  State<GrafikJam> createState() => _GrafikJamState();
}

class _GrafikJamState extends State<GrafikJam> {
  int _dipilih = 0; // indeks batang yang sedang ditandai

  @override
  Widget build(BuildContext context) {
    final List<PrakiraanJam> data = widget.data;
    // Pengaman: tanpa data tidak ada yang bisa digambar. Repositori sudah
    // menolak data kosong, tetapi pemeriksaan ini mencegah galat bila
    // widget dipakai di tempat lain.
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Indeks dibatasi karena jumlah data bisa berubah setelah pembaruan.
    final int indeks = _dipilih.clamp(0, data.length - 1);
    final PrakiraanJam terpilih = data[indeks];
    // Tinggi batang diskalakan terhadap nilai tertinggi, dengan batas bawah
    // 100 supaya hari yang bersih tidak tampak seperti hari yang buruk.
    final double maks = max(100, data.map((p) => p.aqi).reduce(max)).toDouble();

    return KotakBrutal(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pukul ${duaDigit(terpilih.waktu.hour)}.00 · '
            'AQI ${terpilih.aqi} · ${terpilih.kategori.label}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              separatorBuilder: (BuildContext context, int i) =>
                  const SizedBox(width: 6),
              itemBuilder: (BuildContext context, int i) {
                final PrakiraanJam p = data[i];
                final double tinggi = (p.aqi / maks) * 110 + 6;
                return GestureDetector(
                  onTap: () => setState(() => _dipilih = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 26,
                        height: tinggi,
                        decoration: BoxDecoration(
                          color: p.kategori.warna,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: WarnaBrutal.garis,
                            width: i == indeks ? 3.5 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        duaDigit(p.waktu.hour),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              i == indeks ? FontWeight.w900 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
