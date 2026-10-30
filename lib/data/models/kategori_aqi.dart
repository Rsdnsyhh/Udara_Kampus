import 'package:flutter/material.dart';

/// Kategori indeks kualitas udara (US AQI).
///
/// Setiap kategori menyimpan label, warna, ikon, ringkasan kondisi, dan
/// daftar saran. Dengan menyatukan semuanya di satu tempat, tampilan cukup
/// membaca satu objek kategori tanpa perlu percabangan di banyak widget.
enum KategoriAqi {
  baik(
    'Baik',
    Color(0xFF7EE787),
    Icons.sentiment_very_satisfied,
    'Udara bersih dan aman untuk semua aktivitas di luar ruangan.',
    [
      'Aktivitas di luar ruangan aman dilakukan.',
      'Buka jendela agar sirkulasi udara lancar.',
    ],
  ),
  sedang(
    'Sedang',
    Color(0xFFFFE066),
    Icons.sentiment_satisfied,
    'Kualitas udara dapat diterima, tetapi sebagian orang sensitif mungkin terpengaruh.',
    [
      'Kelompok sensitif sebaiknya mengurangi aktivitas berat di luar.',
      'Perhatikan gejala batuk atau sesak napas.',
    ],
  ),
  sensitif(
    'Tidak sehat bagi kelompok sensitif',
    Color(0xFFFFB066),
    Icons.sentiment_neutral,
    'Penderita asma, anak-anak, dan lansia perlu membatasi waktu di luar ruangan.',
    [
      'Kelompok sensitif disarankan tinggal di dalam ruangan.',
      'Gunakan masker bila harus keluar.',
      'Kurangi olahraga di luar ruangan.',
    ],
  ),
  tidakSehat(
    'Tidak sehat',
    Color(0xFFFF7A7A),
    Icons.sentiment_dissatisfied,
    'Seluruh orang mulai dapat merasakan dampak kesehatan dari udara ini.',
    [
      'Gunakan masker saat beraktivitas di luar ruangan.',
      'Tunda olahraga di luar ruangan.',
      'Tutup jendela dan gunakan penyaring udara bila ada.',
    ],
  ),
  sangatTidakSehat(
    'Sangat tidak sehat',
    Color(0xFFC79BFF),
    Icons.sentiment_very_dissatisfied,
    'Risiko kesehatan meningkat bagi seluruh kelompok masyarakat.',
    [
      'Hindari aktivitas di luar ruangan.',
      'Gunakan masker N95 bila terpaksa keluar.',
      'Jaga ruangan tetap tertutup.',
    ],
  ),
  berbahaya(
    'Berbahaya',
    Color(0xFFB5535F),
    Icons.masks,
    'Kondisi darurat kesehatan. Seluruh masyarakat berisiko terdampak serius.',
    [
      'Tetap berada di dalam ruangan.',
      'Gunakan masker N95 bila harus keluar.',
      'Segera cari bantuan medis bila muncul gangguan pernapasan.',
    ],
  );

  const KategoriAqi(this.label, this.warna, this.ikon, this.saran, this.tips);

  final String label;
  final Color warna;
  final IconData ikon;
  final String saran;
  final List<String> tips;

  /// Menentukan kategori dari nilai AQI mengikuti rentang standar US EPA.
  /// Cabang diperiksa dari atas ke bawah, sehingga nilai di atas 300
  /// (termasuk nilai tak wajar yang besar) jatuh ke kategori terakhir.
  static KategoriAqi dariAqi(int aqi) {
    return switch (aqi) {
      <= 50 => KategoriAqi.baik,
      <= 100 => KategoriAqi.sedang,
      <= 150 => KategoriAqi.sensitif,
      <= 200 => KategoriAqi.tidakSehat,
      <= 300 => KategoriAqi.sangatTidakSehat,
      _ => KategoriAqi.berbahaya,
    };
  }
}
