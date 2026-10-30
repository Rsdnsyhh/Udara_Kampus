import 'package:flutter/foundation.dart';

import '../core/konstanta/kota.dart';
import '../data/models/udara.dart';
import '../data/repositories/repositori_udara.dart';
import 'udara_view_model.dart';

/// Hasil pengambilan data untuk satu kota pada halaman peringkat.
class EntriPeringkat {
  const EntriPeringkat({required this.kota, this.udara, this.galat});

  final Kota kota;

  /// Data kota. Null bila pengambilan gagal dan tidak ada cache.
  final Udara? udara;

  /// Galat yang terjadi (bila ada), dipakai untuk menyusun pesan.
  final Object? galat;

  int? get aqi => udara?.saatIni.aqi;
}

/// Mengelola halaman peringkat: mengambil data seluruh kota secara
/// bersamaan lalu mengurutkannya dari udara terbersih ke terkotor.
class PeringkatViewModel extends ChangeNotifier {
  PeringkatViewModel({required RepositoriUdara repositori})
      : _repositori = repositori;

  final RepositoriUdara _repositori;

  StatusMuat _status = StatusMuat.memuat;
  List<EntriPeringkat> _daftar = const [];
  String _pesanGalat = '';
  DateTime? _diperbarui;
  int _nomorPermintaan = 0;
  bool _sudahDibuang = false;

  StatusMuat get status => _status;
  List<EntriPeringkat> get daftar => _daftar;
  String get pesanGalat => _pesanGalat;
  DateTime? get diperbarui => _diperbarui;

  /// Kota dengan AQI terendah (udara terbersih), atau null bila tidak ada data.
  EntriPeringkat? get terbersih {
    for (final EntriPeringkat e in _daftar) {
      if (e.udara != null) return e;
    }
    return null;
  }

  /// Kota dengan AQI tertinggi (udara terkotor), atau null bila tidak ada data.
  EntriPeringkat? get terkotor {
    for (final EntriPeringkat e in _daftar.reversed) {
      if (e.udara != null) return e;
    }
    return null;
  }

  /// True bila sebagian data berasal dari penyimpanan lokal.
  bool get adaDataLama => _daftar.any((e) => e.udara?.dariCache ?? false);

  /// Jumlah kota yang datanya tidak berhasil diperoleh sama sekali.
  int get jumlahTidakTersedia => _daftar.where((e) => e.udara == null).length;

  /// Mengambil data seluruh kota.
  ///
  /// Delapan permintaan dikirim bersamaan dengan Future.wait, sehingga
  /// total waktunya mendekati waktu satu permintaan terlama, bukan jumlah
  /// delapan permintaan berurutan.
  Future<void> muat({bool tampilkanMemuat = true}) async {
    if (_sudahDibuang) return;
    final int nomor = ++_nomorPermintaan;

    if (tampilkanMemuat) {
      _status = StatusMuat.memuat;
      notifyListeners();
    }

    // _ambilSatu tidak pernah melempar galat, sehingga satu kota yang gagal
    // tidak membatalkan tujuh kota lainnya.
    final List<EntriPeringkat> hasil =
        await Future.wait(Kota.values.map(_ambilSatu));
    if (_sudahDibuang || nomor != _nomorPermintaan) return;

    final List<EntriPeringkat> ada = hasil.where((e) => e.udara != null).toList()
      ..sort((a, b) {
        final int banding = a.aqi!.compareTo(b.aqi!);
        // Bila AQI sama, urutkan menurut abjad agar urutan selalu konsisten.
        return banding != 0 ? banding : a.kota.nama.compareTo(b.kota.nama);
      });

    if (ada.isEmpty) {
      Object? galatPertama;
      for (final EntriPeringkat e in hasil) {
        if (e.galat != null) {
          galatPertama = e.galat;
          break;
        }
      }
      _pesanGalat = galatPertama == null
          ? 'Data peringkat tidak dapat dimuat.'
          : pesanRamah(galatPertama);
      _status = StatusMuat.gagal;
    } else {
      // Kota tanpa data diletakkan di urutan terakhir.
      _daftar = [...ada, ...hasil.where((e) => e.udara == null)];
      _diperbarui = DateTime.now();
      _status = StatusMuat.berhasil;
    }
    notifyListeners();
  }

  Future<void> segarkan() => muat(tampilkanMemuat: false);

  /// Mengambil data satu kota. Bila server gagal, dicoba membaca cache.
  /// Fungsi ini sengaja menangkap semua galat dan mengembalikannya sebagai
  /// bagian dari hasil.
  Future<EntriPeringkat> _ambilSatu(Kota kota) async {
    try {
      return EntriPeringkat(kota: kota, udara: await _repositori.ambil(kota));
    } catch (galat) {
      debugPrint('Peringkat: ${kota.nama} gagal ($galat)');
      Udara? cache;
      try {
        cache = await _repositori.ambilCache(kota);
      } catch (_) {
        // Cache yang tidak dapat dibaca diperlakukan seperti tidak ada.
      }
      return EntriPeringkat(kota: kota, udara: cache, galat: galat);
    }
  }

  @override
  void dispose() {
    _sudahDibuang = true;
    super.dispose();
  }
}
