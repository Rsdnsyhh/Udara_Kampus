import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import 'kotak_brutal.dart';

/// Tampilan sementara selama data dimuat.
class TampilanMemuat extends StatelessWidget {
  const TampilanMemuat({
    super.key,
    this.teks = 'Mengambil data udara...',
  });

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: KotakBrutal(
        warna: WarnaBrutal.kuning,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: WarnaBrutal.garis,
              strokeWidth: 5,
            ),
            const SizedBox(height: 14),
            Text(teks, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// Tampilan saat pemuatan gagal, lengkap dengan tombol untuk mencoba lagi.
class TampilanGagal extends StatelessWidget {
  const TampilanGagal({super.key, required this.pesan, required this.onCoba});

  final String pesan;
  final VoidCallback onCoba;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KotakBrutal(
          warna: WarnaBrutal.merahMuda,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const SizedBox(height: 12),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TombolBrutal(
                label: 'Coba lagi',
                ikon: Icons.refresh,
                terpilih: true,
                onTap: onCoba,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
