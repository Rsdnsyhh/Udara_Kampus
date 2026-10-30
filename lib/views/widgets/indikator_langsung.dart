import 'package:flutter/material.dart';

import '../../core/tema/warna_brutal.dart';
import '../../core/utils/format.dart';
import 'kotak_brutal.dart';

/// Penanda status data di bagian atas layar.
///
/// Saat data segar, tampil "LANGSUNG" dengan titik merah berkedip.
/// Bila pembaruan terakhir gagal ([kedaluwarsa]), titik berhenti berkedip
/// dan berubah abu-abu dengan tulisan "DATA LAMA", agar pengguna tahu
/// bahwa angka yang tampil bukan data terbaru.
class IndikatorLangsung extends StatefulWidget {
  const IndikatorLangsung({
    super.key,
    required this.diperbarui,
    this.kedaluwarsa = false,
  });

  final DateTime? diperbarui;
  final bool kedaluwarsa;

  @override
  State<IndikatorLangsung> createState() => _IndikatorLangsungState();
}

class _IndikatorLangsungState extends State<IndikatorLangsung>
    with SingleTickerProviderStateMixin {
  // Pengendali animasi kedipan: naik-turun terus-menerus setiap 0,9 detik.
  late final AnimationController _pengendali = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    // Pengendali wajib dibuang agar tidak terjadi kebocoran memori.
    _pengendali.dispose();
    super.dispose();
  }

  /// Menampilkan jam saja bila data dari hari ini. Data tersimpan dari hari
  /// lain diberi tanggal agar pengguna tidak mengira data tersebut baru.
  String _format(DateTime waktu) {
    final DateTime kini = DateTime.now();
    final String jam = '${duaDigit(waktu.hour)}.${duaDigit(waktu.minute)}';
    final bool hariIni = waktu.year == kini.year &&
        waktu.month == kini.month &&
        waktu.day == kini.day;
    return hariIni ? jam : '${duaDigit(waktu.day)}/${duaDigit(waktu.month)} $jam';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? waktu = widget.diperbarui;
    final String awalan = widget.kedaluwarsa ? 'DATA LAMA' : 'LANGSUNG';
    final String teks = waktu == null ? awalan : '$awalan · ${_format(waktu)}';

    final Widget titik = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: widget.kedaluwarsa ? Colors.grey : const Color(0xFFFF4D4D),
        shape: BoxShape.circle,
        border: Border.all(color: WarnaBrutal.garis, width: 2),
      ),
    );

    return KotakBrutal(
      radius: 30,
      bayangan: 3,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.kedaluwarsa
              ? titik
              : FadeTransition(opacity: _pengendali, child: titik),
          const SizedBox(width: 8),
          Text(
            teks,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
