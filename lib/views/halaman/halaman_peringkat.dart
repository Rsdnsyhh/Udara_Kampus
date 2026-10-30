import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/konstanta/kota.dart';
import '../../core/tema/warna_brutal.dart';
import '../../core/utils/format.dart';
import '../../data/models/kategori_aqi.dart';
import '../../viewmodels/peringkat_view_model.dart';
import '../../viewmodels/udara_view_model.dart';
import '../widgets/kotak_brutal.dart';
import '../widgets/latar_titik.dart';
import '../widgets/muncul_bertahap.dart';
import '../widgets/status_tampilan.dart';

/// Halaman peringkat: membandingkan kualitas udara seluruh kota kampus
/// dari yang terbersih hingga yang terkotor.
class HalamanPeringkat extends StatelessWidget {
  const HalamanPeringkat({super.key, required this.onPilihKota});

  /// Dipanggil saat pengguna mengetuk salah satu kota pada daftar.
  final void Function(Kota kota) onPilihKota;

  @override
  Widget build(BuildContext context) {
    final PeringkatViewModel vm = context.watch<PeringkatViewModel>();

    final Widget isi = switch (vm.status) {
      StatusMuat.berhasil => RefreshIndicator(
          key: const ValueKey('berhasil'),
          color: WarnaBrutal.garis,
          onRefresh: () => context.read<PeringkatViewModel>().segarkan(),
          child: _IsiPeringkat(vm: vm, onPilihKota: onPilihKota),
        ),
      StatusMuat.gagal => TampilanGagal(
          key: const ValueKey('gagal'),
          pesan: vm.pesanGalat,
          onCoba: () => context.read<PeringkatViewModel>().muat(),
        ),
      StatusMuat.memuat => const TampilanMemuat(
          key: ValueKey('memuat'),
          teks: 'Membandingkan delapan kota...',
        ),
    };

    return Scaffold(
      body: SizedBox.expand(
        child: CustomPaint(
          painter: const LatarTitik(),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      TombolBrutal(
                        label: 'Kembali',
                        ikon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: KotakBrutal(
                          warna: WarnaBrutal.merahMuda,
                          radius: 14,
                          bayangan: 4,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.leaderboard),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'PERINGKAT',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: isi,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IsiPeringkat extends StatelessWidget {
  const _IsiPeringkat({required this.vm, required this.onPilihKota});

  final PeringkatViewModel vm;
  final void Function(Kota kota) onPilihKota;

  @override
  Widget build(BuildContext context) {
    final EntriPeringkat? terbersih = vm.terbersih;
    final EntriPeringkat? terkotor = vm.terkotor;
    final DateTime? waktu = vm.diperbarui;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Dua kartu sorotan hanya ditampilkan bila ada dua kota berbeda
        // yang datanya tersedia.
        if (terbersih != null && terkotor != null && terbersih != terkotor)
          MunculBertahap(
            urutan: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _KartuSorotan(
                    judul: 'TERBERSIH',
                    ikon: Icons.eco,
                    entri: terbersih,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _KartuSorotan(
                    judul: 'TERKOTOR',
                    ikon: Icons.warning_amber_rounded,
                    entri: terkotor,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Urutan seluruh kota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        for (int i = 0; i < vm.daftar.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14, right: 4),
            // Jeda animasi dibatasi agar baris di urutan bawah tidak muncul
            // terlalu lambat.
            child: MunculBertahap(
              urutan: min(i + 1, 8),
              child: _BarisPeringkat(
                nomor: i + 1,
                entri: vm.daftar[i],
                onTap: () => onPilihKota(vm.daftar[i].kota),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          [
            if (waktu != null)
              'Diperbarui pukul ${duaDigit(waktu.hour)}.${duaDigit(waktu.minute)}.',
            if (vm.adaDataLama)
              'Ikon jam menandakan data tersimpan di perangkat (bukan terbaru).',
            if (vm.jumlahTidakTersedia > 0)
              '${vm.jumlahTidakTersedia} kota belum dapat dimuat.',
            'Ketuk sebuah kota untuk melihat rinciannya.',
          ].join(' '),
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Kartu kecil untuk kota terbersih atau terkotor.
class _KartuSorotan extends StatelessWidget {
  const _KartuSorotan({
    required this.judul,
    required this.ikon,
    required this.entri,
  });

  final String judul;
  final IconData ikon;
  final EntriPeringkat entri;

  @override
  Widget build(BuildContext context) {
    final int aqi = entri.aqi ?? 0;
    final KategoriAqi kategori = KategoriAqi.dariAqi(aqi);

    return KotakBrutal(
      warna: kategori.warna,
      padding: const EdgeInsets.all(12),
      radius: 18,
      bayangan: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 18),
              const SizedBox(width: 4),
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entri.kota.nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: aqi.toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double nilai, Widget? _) => Text(
              nilai.round().toString(),
              style: const TextStyle(
                fontSize: 44,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            kategori.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Satu baris pada daftar peringkat.
class _BarisPeringkat extends StatelessWidget {
  const _BarisPeringkat({
    required this.nomor,
    required this.entri,
    required this.onTap,
  });

  final int nomor;
  final EntriPeringkat entri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int? aqi = entri.aqi;
    final KategoriAqi? kategori = aqi == null ? null : KategoriAqi.dariAqi(aqi);
    final Color warna = kategori?.warna ?? Colors.grey.shade300;
    // Batang penuh pada AQI 300; nilai minimum menjaga batang tetap terlihat.
    final double isi = aqi == null ? 0 : (aqi / 300).clamp(0.04, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: KotakBrutal(
        padding: const EdgeInsets.all(12),
        radius: 14,
        bayangan: 4,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: warna,
                shape: BoxShape.circle,
                border: Border.all(color: WarnaBrutal.garis, width: 2.5),
              ),
              child: Text(
                aqi == null ? '-' : '$nomor',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entri.kota.nama,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (entri.udara?.dariCache ?? false) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.history, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    kategori?.label ?? 'Data tidak tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
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
                          child: Container(color: warna),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              aqi == null ? '-' : '$aqi',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
