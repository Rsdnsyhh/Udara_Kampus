import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema/warna_brutal.dart';
import '../../data/models/udara.dart';
import '../../data/repositories/repositori_udara.dart';
import '../../viewmodels/peringkat_view_model.dart';
import '../../viewmodels/udara_view_model.dart';
import '../widgets/grafik_jam.dart';
import '../widgets/indikator_langsung.dart';
import '../widgets/kartu_aqi.dart';
import '../widgets/kartu_polutan.dart';
import '../widgets/kartu_saran.dart';
import '../widgets/kotak_brutal.dart';
import '../widgets/latar_titik.dart';
import '../widgets/muncul_bertahap.dart';
import '../widgets/pilihan_kota.dart';
import '../widgets/status_tampilan.dart';
import 'halaman_peringkat.dart';

/// Halaman utama. Halaman ini hanya membaca keadaan dari ViewModel dan
/// memilih tampilan yang sesuai (memuat, gagal, atau data).
class HalamanUdara extends StatelessWidget {
  const HalamanUdara({super.key});

  /// Dipanggil saat pengguna menarik layar untuk menyegarkan. Bila
  /// penyegaran gagal sedangkan data lama masih ada, pengguna diberi tahu
  /// melalui SnackBar tanpa menghapus tampilan yang sudah ada.
  Future<void> _segarkan(BuildContext context) async {
    final UdaraViewModel vm = context.read<UdaraViewModel>();
    await vm.segarkan();
    if (!context.mounted || !vm.kedaluwarsa) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: WarnaBrutal.merahMuda,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: WarnaBrutal.garis, width: 2.5),
          ),
          content: Text(
            '${vm.pesanGalat} Data terakhir tetap ditampilkan.',
            style: const TextStyle(
              color: WarnaBrutal.garis,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  /// Membuka halaman peringkat. ViewModel dan repositori diambil lebih dulu
  /// dari konteks halaman ini, karena halaman baru berada di luar cabang
  /// Provider milik halaman utama.
  void _bukaPeringkat(BuildContext context) {
    final UdaraViewModel vmUtama = context.read<UdaraViewModel>();
    final RepositoriUdara repositori = context.read<RepositoriUdara>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext rute) => ChangeNotifierProvider(
          create: (_) => PeringkatViewModel(repositori: repositori)..muat(),
          child: HalamanPeringkat(
            onPilihKota: (kota) {
              vmUtama.pilihKota(kota);
              Navigator.of(rute).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UdaraViewModel vm = context.watch<UdaraViewModel>();
    final Udara? udara = vm.udara;

    // Warna latar dan aksen mengikuti kategori udara. Latar dicampur putih
    // supaya tetap lembut dan teks mudah dibaca.
    final Color warnaLatar = udara == null
        ? WarnaBrutal.kertas
        : Color.lerp(udara.saatIni.kategori.warna, Colors.white, 0.65)!;
    final Color warnaAksen =
        udara?.saatIni.kategori.warna ?? WarnaBrutal.kuning;

    // Bila status berhasil tetapi data tidak ada (keadaan yang seharusnya
    // tidak terjadi), tampilan memuat dipakai sebagai pengaman.
    final Widget isi = switch (vm.status) {
      StatusMuat.berhasil when udara != null => RefreshIndicator(
          key: ValueKey('berhasil-${vm.kota.name}'),
          color: WarnaBrutal.garis,
          onRefresh: () => _segarkan(context),
          child: _IsiUdara(udara: udara),
        ),
      StatusMuat.gagal => TampilanGagal(
          key: const ValueKey('gagal'),
          pesan: vm.pesanGalat,
          onCoba: () => context.read<UdaraViewModel>().muat(),
        ),
      _ => const TampilanMemuat(key: ValueKey('memuat')),
    };

    return Scaffold(
      // Tombol peringkat melayang di pojok kanan bawah.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        child: TombolBrutal(
          label: 'Peringkat',
          ikon: Icons.leaderboard,
          terpilih: true,
          warna: WarnaBrutal.merahMuda,
          onTap: () => _bukaPeringkat(context),
        ),
      ),
      body: AnimatedContainer(
        width: double.infinity,
        height: double.infinity,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        color: warnaLatar,
        child: CustomPaint(
          painter: const LatarTitik(),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: KotakBrutal(
                          warna: WarnaBrutal.kuning,
                          radius: 14,
                          bayangan: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.air),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'UDARA KAMPUS',
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
                      const SizedBox(width: 12),
                      IndikatorLangsung(
                        diperbarui: vm.diperbarui,
                        kedaluwarsa: vm.kedaluwarsa,
                      ),
                    ],
                  ),
                ),
                PilihanKota(warnaTerpilih: warnaAksen),
                // AnimatedSwitcher memberi transisi halus antara tampilan
                // memuat, gagal, dan data.
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

/// Isi halaman saat data tersedia, dalam bentuk daftar yang dapat digulir.
class _IsiUdara extends StatelessWidget {
  const _IsiUdara({required this.udara});

  final Udara udara;

  Widget _judul(String teks) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Selalu dapat digulir, agar tarik-untuk-menyegarkan tetap berfungsi
      // walaupun isinya pendek.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        MunculBertahap(urutan: 0, child: KartuAqi(udara: udara)),
        const SizedBox(height: 24),
        MunculBertahap(
          urutan: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _judul('Rincian polutan'),
              GrafikPolutan(daftar: udara.saatIni.polutan),
            ],
          ),
        ),
        const SizedBox(height: 24),
        MunculBertahap(
          urutan: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _judul('Prakiraan 24 jam'),
              GrafikJam(data: udara.perJam),
            ],
          ),
        ),
        const SizedBox(height: 24),
        MunculBertahap(
          urutan: 3,
          child: KartuSaran(kategori: udara.saatIni.kategori),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sumber data: Open-Meteo Air Quality API (CC BY 4.0). Data '
          'diperbarui otomatis setiap 5 menit. Tarik ke bawah untuk '
          'menyegarkan secara manual.',
          style: TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
