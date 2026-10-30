import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/konstanta/kota.dart';
import '../models/udara.dart';
import '../services/layanan_udara.dart';
import '../services/penyimpanan_lokal.dart';

/// Kontrak sumber data udara. ViewModel hanya bergantung pada kelas
/// abstrak ini sehingga sumber datanya mudah diganti atau ditiru saat uji.
abstract class RepositoriUdara {
  /// Mengambil data terbaru dari server.
  Future<Udara> ambil(Kota kota);

  /// Membaca data terakhir yang tersimpan di perangkat. Mengembalikan null
  /// bila belum ada data tersimpan atau data tersebut tidak dapat dibaca.
  Future<Udara?> ambilCache(Kota kota);
}

/// Implementasi yang mengubah JSON Open-Meteo menjadi model aplikasi dan,
/// bila [penyimpanan] diberikan, menyimpan jawaban terakhir sebagai cadangan
/// untuk keadaan tanpa koneksi.
class RepositoriUdaraOpenMeteo implements RepositoriUdara {
  RepositoriUdaraOpenMeteo({
    required LayananUdara layanan,
    PenyimpananLokal? penyimpanan,
  })  : _layanan = layanan,
        _penyimpanan = penyimpanan;

  final LayananUdara _layanan;
  final PenyimpananLokal? _penyimpanan;

  @override
  Future<Udara> ambil(Kota kota) async {
    final Map<String, dynamic> json = await _layanan.ambilKualitasUdara(
      lintang: kota.lintang,
      bujur: kota.bujur,
    );
    final DateTime waktu = DateTime.now();
    final Udara udara = _dariJson(kota, json, waktu, dariCache: false);

    // Data disimpan hanya setelah berhasil dibaca. Dengan begitu cache
    // tidak pernah berisi data yang rusak.
    try {
      await _penyimpanan?.simpanCache(kota, jsonEncode(json), waktu);
    } catch (galat) {
      debugPrint('Cache tidak tersimpan: $galat');
    }
    return udara;
  }

  @override
  Future<Udara?> ambilCache(Kota kota) async {
    try {
      final EntriCache? entri = await _penyimpanan?.bacaCache(kota);
      if (entri == null) return null;
      final Object? isi = jsonDecode(entri.json);
      if (isi is! Map<String, dynamic>) return null;
      return _dariJson(kota, isi, entri.waktu, dariCache: true);
    } catch (galat) {
      // Cache yang rusak diperlakukan sama seperti cache yang tidak ada.
      debugPrint('Cache ${kota.nama} tidak dapat dibaca: $galat');
      return null;
    }
  }

  /// Membentuk model [Udara] dari JSON. Dipakai bersama oleh data dari
  /// server dan data dari cache, sehingga aturan validasinya sama.
  Udara _dariJson(
    Kota kota,
    Map<String, dynamic> json,
    DateTime waktu, {
    required bool dariCache,
  }) {
    try {
      // Pattern matching memastikan bagian "current" dan "hourly" ada dan
      // bertipe Map sebelum diproses lebih lanjut.
      return switch (json) {
        {
          'current': final Map<String, dynamic> saatIni,
          'hourly': final Map<String, dynamic> perJam,
        } =>
          Udara(
            kota: kota,
            saatIni: _saatIni(saatIni),
            perJam: _perJam(perJam),
            diambilPada: waktu,
            dariCache: dariCache,
          ),
        _ => throw const FormatException('Bentuk data udara tidak sesuai'),
      };
    } on TypeError {
      // Tipe data yang tidak terduga (misalnya teks di tempat angka)
      // diubah menjadi FormatException agar ditangani seragam di ViewModel.
      throw const FormatException('Tipe data dari server tidak sesuai');
    }
  }

  /// Mengubah nilai JSON menjadi angka. Nilai yang bukan angka, tak
  /// hingga, atau negatif dianggap tidak valid dan dikembalikan sebagai
  /// null, karena kadar polutan tidak mungkin bernilai negatif.
  double? _angka(Object? nilai) {
    return nilai is num && nilai.isFinite && nilai >= 0
        ? nilai.toDouble()
        : null;
  }

  /// Membentuk data kondisi saat ini. AQI wajib ada; tanpa AQI tampilan
  /// utama tidak dapat dibuat sehingga proses dihentikan dengan galat.
  UdaraSaatIni _saatIni(Map<String, dynamic> json) {
    final Object? aqi = json['us_aqi'];
    if (aqi is! num || !aqi.isFinite || aqi < 0) {
      throw const FormatException('Indeks AQI tidak tersedia');
    }
    // Batas pembanding mengikuti pedoman WHO 2021 (rata-rata 24 jam;
    // ozon rata-rata 8 jam). Karbon monoksida: 4 mg/m³ = 4000 µg/m³.
    return UdaraSaatIni(
      aqi: aqi.round(),
      polutan: [
        Polutan(
          nama: 'Partikel halus',
          simbol: 'PM2.5',
          nilai: _angka(json['pm2_5']),
          satuan: 'µg/m³',
          batas: 15,
        ),
        Polutan(
          nama: 'Partikel kasar',
          simbol: 'PM10',
          nilai: _angka(json['pm10']),
          satuan: 'µg/m³',
          batas: 45,
        ),
        Polutan(
          nama: 'Nitrogen dioksida',
          simbol: 'NO₂',
          nilai: _angka(json['nitrogen_dioxide']),
          satuan: 'µg/m³',
          batas: 25,
        ),
        Polutan(
          nama: 'Sulfur dioksida',
          simbol: 'SO₂',
          nilai: _angka(json['sulphur_dioxide']),
          satuan: 'µg/m³',
          batas: 40,
        ),
        Polutan(
          nama: 'Ozon',
          simbol: 'O₃',
          nilai: _angka(json['ozone']),
          satuan: 'µg/m³',
          batas: 100,
        ),
        Polutan(
          nama: 'Karbon monoksida',
          simbol: 'CO',
          nilai: _angka(json['carbon_monoxide']),
          satuan: 'µg/m³',
          batas: 4000,
        ),
      ],
    );
  }

  /// Membentuk daftar AQI per jam.
  ///
  /// Data dari server berbentuk "array sejajar": time[i] berpasangan dengan
  /// us_aqi[i]. Pasangan yang waktunya tidak dapat dibaca atau nilainya
  /// kosong dilewati, sehingga satu data rusak tidak menggagalkan seluruh
  /// grafik.
  List<PrakiraanJam> _perJam(Map<String, dynamic> json) {
    if (json case {
      'time': final List<dynamic> waktu,
      'us_aqi': final List<dynamic> aqi,
    }) {
      if (waktu.length != aqi.length) {
        throw const FormatException('Panjang data per jam tidak sama');
      }
      final List<PrakiraanJam> hasil = [];
      for (int i = 0; i < waktu.length; i++) {
        final Object? w = waktu[i];
        final Object? a = aqi[i];
        final DateTime? tanggal = w is String ? DateTime.tryParse(w) : null;
        if (tanggal == null || a is! num || !a.isFinite || a < 0) {
          continue;
        }
        hasil.add(PrakiraanJam(waktu: tanggal, aqi: a.round()));
      }
      if (hasil.isEmpty) {
        throw const FormatException('Data per jam kosong');
      }
      return hasil;
    }
    throw const FormatException('Bentuk data per jam tidak sesuai');
  }
}
