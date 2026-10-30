import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/konstanta/kota.dart';
import '../data/models/udara.dart';
import '../data/repositories/repositori_udara.dart';
import '../data/services/layanan_udara.dart';
import '../data/services/penyimpanan_lokal.dart';

/// Tiga keadaan layar: sedang memuat, data siap, atau gagal.
enum StatusMuat { memuat, berhasil, gagal }

/// Mengubah galat teknis menjadi kalimat yang dapat dipahami pengguna.
/// Rincian teknis tidak ditampilkan di layar, tetapi dicatat lewat
/// debugPrint untuk keperluan penelusuran.
String pesanRamah(Object galat) {
  return switch (galat) {
    TimeoutException() => 'Server terlalu lama menjawab. Silakan coba lagi.',
    ApiException(kodeStatus: 429) =>
      'Permintaan terlalu sering. Mohon tunggu sebentar lalu coba lagi.',
    ApiException(kodeStatus: >= 500) =>
      'Server sedang bermasalah. Silakan coba lagi nanti.',
    ApiException() => 'Permintaan data ditolak oleh server.',
    FormatException() => 'Data dari server tidak dapat dibaca.',
    ArgumentError() => 'Lokasi kota tidak valid.',
    http.ClientException() =>
      'Tidak dapat terhubung. Periksa koneksi internet Anda.',
    _ => 'Terjadi kesalahan yang tidak terduga.',
  };
}

/// Pengelola status halaman. Seluruh logika (kota terpilih, pemuatan,
/// penanganan galat, penyimpanan lokal, pembaruan berkala) berada di sini,
/// sedangkan View hanya menampilkan keadaan yang tersedia.
class UdaraViewModel extends ChangeNotifier {
  UdaraViewModel({
    required RepositoriUdara repositori,
    PenyimpananLokal? penyimpanan,
    this.selangWaktu = const Duration(minutes: 5),
  })  : _repositori = repositori,
        _penyimpanan = penyimpanan;

  final RepositoriUdara _repositori;
  final PenyimpananLokal? _penyimpanan;

  /// Selang antarpembaruan otomatis.
  final Duration selangWaktu;

  Kota _kota = Kota.jakarta;
  StatusMuat _status = StatusMuat.memuat;
  Udara? _udara;
  DateTime? _diperbarui;
  String _pesanGalat = '';
  bool _kedaluwarsa = false;
  bool _kotaDipilihPengguna = false;
  int _nomorPermintaan = 0;
  bool _sudahDibuang = false;
  Timer? _pewaktu;

  Kota get kota => _kota;
  StatusMuat get status => _status;
  Udara? get udara => _udara;
  DateTime? get diperbarui => _diperbarui;
  String get pesanGalat => _pesanGalat;

  /// True bila yang tampil adalah data lama, baik karena pembaruan terakhir
  /// gagal maupun karena data dibaca dari penyimpanan lokal.
  bool get kedaluwarsa => _kedaluwarsa;

  /// Dipanggil sekali saat aplikasi dibuka: memulihkan kota yang terakhir
  /// dipilih, memuat data, lalu memulai pembaruan berkala.
  Future<void> mulai() async {
    String? tersimpan;
    try {
      tersimpan = await _penyimpanan?.bacaKotaTerakhir();
    } catch (galat) {
      debugPrint('Gagal memulihkan kota: $galat');
    }
    if (_sudahDibuang) return;

    // Kota tersimpan dipakai hanya bila pengguna belum sempat memilih
    // kota lain selama pembacaan berlangsung. Nama yang tidak dikenal
    // (misalnya kota yang sudah dihapus dari daftar) diabaikan.
    if (!_kotaDipilihPengguna && tersimpan != null) {
      for (final Kota k in Kota.values) {
        if (k.name == tersimpan) {
          _kota = k;
          break;
        }
      }
    }
    mulaiPemantauan();
    await muat();
  }

  /// Memuat data untuk kota yang sedang dipilih.
  ///
  /// [tampilkanMemuat] bernilai false saat layar ditarik untuk menyegarkan
  /// atau saat pembaruan otomatis; data lama tetap terlihat selama menunggu.
  /// Bila pembaruan semacam itu gagal, data lama dipertahankan dan hanya
  /// ditandai kedaluwarsa.
  ///
  /// Bila pemuatan awal gagal, aplikasi mencoba membaca data tersimpan di
  /// perangkat sehingga layar tidak kosong saat tanpa koneksi.
  Future<void> muat({bool tampilkanMemuat = true}) async {
    if (_sudahDibuang) return;

    // Setiap permintaan diberi nomor. Bila pengguna berpindah kota sebelum
    // jawaban lama tiba, nomornya sudah tidak sama dan jawaban itu diabaikan.
    final int nomor = ++_nomorPermintaan;
    final Kota kotaDiminta = _kota;

    if (tampilkanMemuat) {
      _status = StatusMuat.memuat;
      notifyListeners();
    }
    try {
      final Udara data = await _repositori.ambil(kotaDiminta);
      if (_sudahDibuang || nomor != _nomorPermintaan) {
        return;
      }
      _udara = data;
      _diperbarui = data.diambilPada;
      _kedaluwarsa = false;
      _status = StatusMuat.berhasil;
    } catch (galat) {
      if (_sudahDibuang || nomor != _nomorPermintaan) {
        return;
      }
      debugPrint('Galat saat memuat data udara: $galat');
      _pesanGalat = pesanRamah(galat);

      if (_udara != null && !tampilkanMemuat) {
        _kedaluwarsa = true; // data lama yang sedang tampil dipertahankan
      } else {
        final Udara? cache = await _bacaCache(kotaDiminta);
        if (_sudahDibuang || nomor != _nomorPermintaan) {
          return;
        }
        if (cache != null) {
          _udara = cache;
          _diperbarui = cache.diambilPada;
          _kedaluwarsa = true;
          _status = StatusMuat.berhasil;
        } else {
          _status = StatusMuat.gagal;
        }
      }
    }
    notifyListeners();
  }

  /// Membaca cache tanpa pernah melempar galat.
  Future<Udara?> _bacaCache(Kota kota) async {
    try {
      return await _repositori.ambilCache(kota);
    } catch (galat) {
      debugPrint('Gagal membaca cache: $galat');
      return null;
    }
  }

  /// Dipanggil oleh gerakan tarik-untuk-menyegarkan.
  Future<void> segarkan() => muat(tampilkanMemuat: false);

  /// Memulai pembaruan berkala. Pewaktu lama dibatalkan lebih dulu agar
  /// tidak ada dua pewaktu yang berjalan bersamaan.
  void mulaiPemantauan() {
    _pewaktu?.cancel();
    _pewaktu = Timer.periodic(selangWaktu, (_) {
      muat(tampilkanMemuat: false);
    });
  }

  /// Mengganti kota dan menyimpannya sebagai kota terakhir. Data kota
  /// sebelumnya dihapus supaya tampilan tidak menunjukkan data kota lain
  /// selama data baru dimuat.
  void pilihKota(Kota kota) {
    if (kota == _kota || _sudahDibuang) {
      return;
    }
    _kotaDipilihPengguna = true;
    _kota = kota;
    _udara = null;
    _kedaluwarsa = false;
    unawaited(_penyimpanan?.simpanKotaTerakhir(kota.name));
    muat();
  }

  @override
  void dispose() {
    // Penanda ini mencegah notifyListeners dipanggil setelah objek dibuang,
    // yang dapat terjadi bila jawaban server tiba terlambat.
    _sudahDibuang = true;
    _pewaktu?.cancel();
    super.dispose();
  }
}
