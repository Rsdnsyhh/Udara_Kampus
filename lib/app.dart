import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/tema/warna_brutal.dart';
import 'data/repositories/repositori_udara.dart';
import 'data/services/penyimpanan_lokal.dart';
import 'viewmodels/udara_view_model.dart';
import 'views/halaman/halaman_udara.dart';

/// Widget akar yang mengatur tema dan menyediakan ViewModel untuk halaman utama.
class AplikasiUdara extends StatelessWidget {
  const AplikasiUdara({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Udara Kampus',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WarnaBrutal.kertas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WarnaBrutal.kuning,
          brightness: Brightness.light,
        ),
        // Warna teks disamakan dengan warna garis agar kontras tetap tinggi.
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: WarnaBrutal.garis,
              displayColor: WarnaBrutal.garis,
            ),
      ),
      home: ChangeNotifierProvider(
        // mulai() memulihkan kota terakhir, memuat data, lalu menjalankan
        // pembaruan berkala. Operator cascade (..) menjaga agar yang
        // dikembalikan tetap objek ViewModel.
        create: (BuildContext context) => UdaraViewModel(
          repositori: context.read<RepositoriUdara>(),
          penyimpanan: context.read<PenyimpananLokal>(),
        )..mulai(),
        child: const HalamanUdara(),
      ),
    );
  }
}
