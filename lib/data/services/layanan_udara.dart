import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Galat yang dilempar ketika server menjawab dengan kode status selain 200.
class ApiException implements Exception {
  const ApiException(this.kodeStatus, [this.alasan]);

  final int kodeStatus;

  /// Keterangan dari server (bila ada), berguna untuk penelusuran masalah.
  final String? alasan;

  @override
  String toString() => 'ApiException: kode status $kodeStatus'
      '${alasan == null ? '' : ' ($alasan)'}';
}

/// Lapisan yang berhubungan langsung dengan Open-Meteo Air Quality API.
/// Tugasnya hanya mengirim permintaan dan mengembalikan JSON mentah;
/// pengubahan JSON menjadi model dilakukan oleh repositori.
class LayananUdara {
  LayananUdara({
    http.Client? klien,
    this.batasWaktu = const Duration(seconds: 10),
    this.maksPercobaan = 3,
    this.jedaUlang = const Duration(seconds: 1),
  })  : assert(maksPercobaan >= 1, 'maksPercobaan minimal 1'),
        _klien = klien ?? http.Client();

  final http.Client _klien;

  /// Waktu tunggu maksimum untuk satu permintaan.
  final Duration batasWaktu;

  /// Jumlah maksimum percobaan (termasuk percobaan pertama) untuk galat
  /// yang bersifat sementara.
  final int maksPercobaan;

  /// Jeda dasar antarpercobaan; makin lama pada percobaan berikutnya.
  final Duration jedaUlang;

  /// Mengambil data kualitas udara untuk satu titik koordinat.
  ///
  /// Galat sementara (waktu habis, gangguan jaringan, kode 5xx) dicoba ulang
  /// otomatis. Galat yang sifatnya tetap (misalnya kode 400 atau JSON rusak)
  /// langsung dilempar karena percobaan ulang tidak akan mengubah hasilnya.
  Future<Map<String, dynamic>> ambilKualitasUdara({
    required double lintang,
    required double bujur,
  }) async {
    // Koordinat diperiksa lebih dulu agar permintaan yang pasti ditolak
    // server tidak perlu dikirim.
    if (!lintang.isFinite ||
        !bujur.isFinite ||
        lintang < -90 ||
        lintang > 90 ||
        bujur < -180 ||
        bujur > 180) {
      throw ArgumentError('Koordinat tidak valid: $lintang, $bujur');
    }

    final Uri alamat =
        Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': '$lintang',
      'longitude': '$bujur',
      'current': 'us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,'
          'sulphur_dioxide,ozone',
      'hourly': 'us_aqi',
      'forecast_hours': '24',
      'timezone': 'auto', // jam mengikuti zona waktu kota yang bersangkutan
    });

    for (int percobaan = 1;; percobaan++) {
      try {
        return await _kirimSekali(alamat);
      } catch (galat) {
        if (!_bisaDiulang(galat) || percobaan >= maksPercobaan) {
          rethrow;
        }
        debugPrint('Percobaan $percobaan gagal ($galat), mengulang...');
        await Future<void>.delayed(jedaUlang * percobaan);
      }
    }
  }

  /// Mengirim satu permintaan GET, memeriksa kode status, dan membaca JSON.
  Future<Map<String, dynamic>> _kirimSekali(Uri alamat) async {
    debugPrint('GET $alamat');
    final http.Response respons = await _klien
        .get(alamat, headers: {'Accept': 'application/json'})
        .timeout(batasWaktu);

    // bodyBytes didecode manual sebagai UTF-8 agar karakter khusus tidak
    // rusak, apa pun header charset yang dikirim server.
    final Object? isi = _bacaJson(respons);

    if (respons.statusCode != 200) {
      // Open-Meteo menjelaskan sebab penolakan pada kunci "reason".
      final String? alasan =
          (isi is Map && isi['reason'] is String) ? isi['reason'] as String : null;
      throw ApiException(respons.statusCode, alasan);
    }
    if (isi is! Map<String, dynamic>) {
      throw const FormatException('Bentuk JSON tidak dikenal');
    }
    // Server dapat menjawab 200 tetapi tetap menandai adanya galat.
    if (isi['error'] == true) {
      throw FormatException('Server melaporkan galat: ${isi['reason']}');
    }
    return isi;
  }

  /// Membaca isi respons sebagai JSON. Pada respons galat isinya mungkin
  /// bukan JSON (misalnya halaman HTML), maka kegagalan baca ditandai null
  /// agar kode status tetap dapat dilaporkan dengan benar.
  Object? _bacaJson(http.Response respons) {
    try {
      return jsonDecode(utf8.decode(respons.bodyBytes));
    } on FormatException {
      if (respons.statusCode == 200) rethrow;
      return null;
    }
  }

  /// Menentukan apakah suatu galat layak dicoba ulang.
  /// Kode 429 (terlalu banyak permintaan) sengaja tidak diulang karena
  /// pengulangan cepat justru memperburuk keadaan.
  bool _bisaDiulang(Object galat) {
    return switch (galat) {
      TimeoutException() => true,
      http.ClientException() => true,
      ApiException(kodeStatus: >= 500) => true,
      _ => false,
    };
  }

  /// Menutup klien HTTP. Dipanggil sekali saat aplikasi berakhir.
  void tutup() => _klien.close();
}
