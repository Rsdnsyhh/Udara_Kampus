import '../../core/konstanta/kota.dart';
import 'kategori_aqi.dart';

/// Satu jenis polutan beserta kadarnya saat ini.
class Polutan {
  const Polutan({
    required this.nama,
    required this.simbol,
    required this.nilai,
    required this.satuan,
    required this.batas,
  });

  final String nama;
  final String simbol;

  /// Kadar polutan. Bernilai null bila server tidak mengirim datanya
  /// atau datanya tidak valid.
  final double? nilai;
  final String satuan;

  /// Batas pedoman WHO (rata-rata 24 jam) yang dipakai sebagai pembanding.
  final double batas;

  /// Perbandingan kadar terhadap batas pedoman. Nilai 1.0 berarti tepat
  /// berada di batas. Hasilnya null bila kadar tidak tersedia.
  double? get rasio {
    final double? n = nilai;
    return n == null ? null : n / batas;
  }
}

/// Kondisi udara pada saat data diambil.
class UdaraSaatIni {
  const UdaraSaatIni({required this.aqi, required this.polutan});

  final int aqi;
  final List<Polutan> polutan;

  KategoriAqi get kategori => KategoriAqi.dariAqi(aqi);
}

/// Nilai AQI untuk satu jam tertentu pada grafik prakiraan.
class PrakiraanJam {
  const PrakiraanJam({required this.waktu, required this.aqi});

  final DateTime waktu;
  final int aqi;

  KategoriAqi get kategori => KategoriAqi.dariAqi(aqi);
}

/// Gabungan seluruh data yang ditampilkan untuk satu kota.
class Udara {
  const Udara({
    required this.kota,
    required this.saatIni,
    required this.perJam,
    required this.diambilPada,
    this.dariCache = false,
  });

  final Kota kota;
  final UdaraSaatIni saatIni;
  final List<PrakiraanJam> perJam;

  /// Waktu data ini diterima dari server (bukan waktu data ditampilkan).
  final DateTime diambilPada;

  /// True bila data dibaca dari penyimpanan lokal, bukan dari server.
  final bool dariCache;
}
