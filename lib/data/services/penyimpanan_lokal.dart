import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/konstanta/kota.dart';

/// Satu data tersimpan: isi JSON dari server beserta waktu penyimpanannya.
class EntriCache {
  const EntriCache({required this.json, required this.waktu});

  final String json;
  final DateTime waktu;
}

/// Kontrak penyimpanan lokal. Dibuat abstrak agar pengujian dapat memakai
/// penyimpanan di memori tanpa menyentuh perangkat.
///
/// Seluruh implementasi tidak boleh melempar galat: kegagalan menyimpan
/// atau membaca tidak boleh mengganggu fungsi utama aplikasi.
abstract class PenyimpananLokal {
  Future<String?> bacaKotaTerakhir();
  Future<void> simpanKotaTerakhir(String namaKota);
  Future<EntriCache?> bacaCache(Kota kota);
  Future<void> simpanCache(Kota kota, String json, DateTime waktu);
}

/// Implementasi nyata berbasis shared_preferences.
class PenyimpananSharedPrefs implements PenyimpananLokal {
  static const String _kunciKota = 'kota_terakhir';
  static String _kunciJson(Kota k) => 'cache_json_${k.name}';
  static String _kunciWaktu(Kota k) => 'cache_waktu_${k.name}';

  @override
  Future<String?> bacaKotaTerakhir() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kunciKota);
    } catch (galat) {
      debugPrint('Gagal membaca kota terakhir: $galat');
      return null;
    }
  }

  @override
  Future<void> simpanKotaTerakhir(String namaKota) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kunciKota, namaKota);
    } catch (galat) {
      debugPrint('Gagal menyimpan kota terakhir: $galat');
    }
  }

  @override
  Future<EntriCache?> bacaCache(Kota kota) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_kunciJson(kota));
      final int? milidetik = prefs.getInt(_kunciWaktu(kota));
      // Data dianggap tidak ada bila salah satu bagiannya hilang.
      if (json == null || milidetik == null) return null;
      return EntriCache(
        json: json,
        waktu: DateTime.fromMillisecondsSinceEpoch(milidetik),
      );
    } catch (galat) {
      debugPrint('Gagal membaca cache ${kota.nama}: $galat');
      return null;
    }
  }

  @override
  Future<void> simpanCache(Kota kota, String json, DateTime waktu) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kunciJson(kota), json);
      await prefs.setInt(_kunciWaktu(kota), waktu.millisecondsSinceEpoch);
    } catch (galat) {
      debugPrint('Gagal menyimpan cache ${kota.nama}: $galat');
    }
  }
}

/// Penyimpanan di memori, dipakai pada pengujian.
class PenyimpananMemori implements PenyimpananLokal {
  PenyimpananMemori({String? kotaTerakhir}) : _kota = kotaTerakhir;

  String? _kota;
  final Map<Kota, EntriCache> _cache = {};

  @override
  Future<String?> bacaKotaTerakhir() async => _kota;

  @override
  Future<void> simpanKotaTerakhir(String namaKota) async => _kota = namaKota;

  @override
  Future<EntriCache?> bacaCache(Kota kota) async => _cache[kota];

  @override
  Future<void> simpanCache(Kota kota, String json, DateTime waktu) async {
    _cache[kota] = EntriCache(json: json, waktu: waktu);
  }
}
