import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/konstanta/kota.dart';
import '../../viewmodels/udara_view_model.dart';
import 'kotak_brutal.dart';

/// Baris tombol kota yang dapat digulir ke samping.
class PilihanKota extends StatelessWidget {
  const PilihanKota({super.key, required this.warnaTerpilih});

  /// Warna tombol yang sedang dipilih (mengikuti kategori udara).
  final Color warnaTerpilih;

  @override
  Widget build(BuildContext context) {
    // select: widget ini hanya dibangun ulang bila kota terpilih berubah,
    // bukan setiap kali ViewModel memberi tahu perubahan lain.
    final Kota terpilih = context.select((UdaraViewModel vm) => vm.kota);

    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final Kota kota in Kota.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TombolBrutal(
                label: kota.nama,
                terpilih: kota == terpilih,
                warna: warnaTerpilih,
                onTap: () => context.read<UdaraViewModel>().pilihKota(kota),
              ),
            ),
        ],
      ),
    );
  }
}
