import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/repositori_udara.dart';
import 'data/services/layanan_udara.dart';
import 'data/services/penyimpanan_lokal.dart';

/// Titik masuk aplikasi.
///
/// Layanan dan repositori didaftarkan di sini sekali saja, sehingga seluruh
/// aplikasi memakai satu klien HTTP yang sama. Pendaftaran ini juga
/// memudahkan pengujian karena objek tiruan dapat dipasang sebagai pengganti.
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<LayananUdara>(
          create: (BuildContext context) => LayananUdara(),
          // Klien HTTP ditutup saat aplikasi berakhir agar sumber daya
          // jaringan dilepas dengan benar.
          dispose: (BuildContext context, LayananUdara layanan) =>
              layanan.tutup(),
        ),
        Provider<PenyimpananLokal>(
          create: (BuildContext context) => PenyimpananSharedPrefs(),
        ),
        Provider<RepositoriUdara>(
          create: (BuildContext context) => RepositoriUdaraOpenMeteo(
            layanan: context.read<LayananUdara>(),
            penyimpanan: context.read<PenyimpananLokal>(),
          ),
        ),
      ],
      child: const AplikasiUdara(),
    ),
  );
}
