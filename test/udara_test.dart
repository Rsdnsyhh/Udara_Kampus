import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udara_kampus/core/konstanta/kota.dart';
import 'package:udara_kampus/data/models/kategori_aqi.dart';
import 'package:udara_kampus/data/models/udara.dart';
import 'package:udara_kampus/data/repositories/repositori_udara.dart';
import 'package:udara_kampus/data/services/layanan_udara.dart';
import 'package:udara_kampus/data/services/penyimpanan_lokal.dart';
import 'package:udara_kampus/viewmodels/peringkat_view_model.dart';
import 'package:udara_kampus/viewmodels/udara_view_model.dart';

// Jawaban "server" tiruan. Nilai PM10 sengaja dikosongkan (null), dan data
// jam ketiga dikosongkan untuk menguji penanganan data yang tidak lengkap.
const String contohJson = '''
{
  "latitude": -0.5,
  "longitude": 117.125,
  "timezone": "Asia/Makassar",
  "current": {
    "time": "2026-10-15T14:00",
    "us_aqi": 87,
    "pm2_5": 28.4,
    "pm10": null,
    "carbon_monoxide": 310,
    "nitrogen_dioxide": 12.5,
    "sulphur_dioxide": 6.1,
    "ozone": 54
  },
  "hourly": {
    "time": ["2026-10-15T14:00", "2026-10-15T15:00", "2026-10-15T16:00"],
    "us_aqi": [87, 120, null]
  }
}
''';

/// Membuat layanan dengan klien tiruan. Jeda percobaan ulang dinolkan
/// agar pengujian berjalan cepat.
LayananUdara layananDengan(http.Response Function(http.Request) jawab) {
  return LayananUdara(
    klien: MockClient((http.Request p) async => jawab(p)),
    jedaUlang: Duration.zero,
  );
}

RepositoriUdara repoDengan(http.Response Function(http.Request) jawab) {
  return RepositoriUdaraOpenMeteo(layanan: layananDengan(jawab));
}

/// Repositori palsu yang mengembalikan jawaban secara berurutan.
/// Isi daftar berupa objek Udara (berhasil) atau objek galat (gagal).
/// Parameter [cache] menentukan data yang dikembalikan oleh ambilCache.
class RepoPalsu implements RepositoriUdara {
  RepoPalsu(this.jawaban, {this.cache});

  final List<Object> jawaban;
  final Udara? cache;
  int _panggilan = 0;

  @override
  Future<Udara> ambil(Kota kota) async {
    final Object j = jawaban[_panggilan++ % jawaban.length];
    if (j is Udara) return j;
    throw j;
  }

  @override
  Future<Udara?> ambilCache(Kota kota) async => cache;
}

/// Membuat data Udara sederhana dengan nilai AQI tertentu.
Udara buatUdara(Kota kota, int aqi, {bool dariCache = false}) {
  return Udara(
    kota: kota,
    saatIni: UdaraSaatIni(aqi: aqi, polutan: const []),
    perJam: [PrakiraanJam(waktu: DateTime(2026, 10, 15, 14), aqi: aqi)],
    diambilPada: DateTime(2026, 10, 15, 14),
    dariCache: dariCache,
  );
}

/// Repositori palsu untuk uji peringkat: nilai AQI ditentukan per kota,
/// sedangkan nilai null berarti pengambilan data kota itu gagal.
class RepoPerKota implements RepositoriUdara {
  RepoPerKota(this.aturan, {this.cache = const {}});

  final Map<Kota, int?> aturan;
  final Map<Kota, Udara> cache;

  @override
  Future<Udara> ambil(Kota kota) async {
    final int? aqi = aturan[kota];
    if (aqi == null) throw const ApiException(503);
    return buatUdara(kota, aqi);
  }

  @override
  Future<Udara?> ambilCache(Kota kota) async => cache[kota];
}

void main() {
  group('KategoriAqi', () {
    test('batas kategori sesuai skala US AQI', () {
      expect(KategoriAqi.dariAqi(0), KategoriAqi.baik);
      expect(KategoriAqi.dariAqi(50), KategoriAqi.baik);
      expect(KategoriAqi.dariAqi(51), KategoriAqi.sedang);
      expect(KategoriAqi.dariAqi(150), KategoriAqi.sensitif);
      expect(KategoriAqi.dariAqi(200), KategoriAqi.tidakSehat);
      expect(KategoriAqi.dariAqi(300), KategoriAqi.sangatTidakSehat);
      expect(KategoriAqi.dariAqi(301), KategoriAqi.berbahaya);
    });
  });

  group('Layanan', () {
    test('mengulang permintaan saat server menjawab 500, lalu berhasil', () async {
      int panggilan = 0;
      final LayananUdara layanan = layananDengan((_) {
        panggilan++;
        return panggilan < 3
            ? http.Response('{}', 500)
            : http.Response(contohJson, 200);
      });
      final Map<String, dynamic> hasil =
          await layanan.ambilKualitasUdara(lintang: -0.5, bujur: 117.15);
      expect(panggilan, 3);
      expect(hasil['current'], isNotNull);
    });

    test('tidak mengulang saat server menjawab 400', () async {
      int panggilan = 0;
      final LayananUdara layanan = layananDengan((_) {
        panggilan++;
        return http.Response('{"error":true,"reason":"Latitude salah"}', 400);
      });
      await expectLater(
        layanan.ambilKualitasUdara(lintang: -0.5, bujur: 117.15),
        throwsA(isA<ApiException>()
            .having((e) => e.kodeStatus, 'kodeStatus', 400)
            .having((e) => e.alasan, 'alasan', 'Latitude salah')),
      );
      expect(panggilan, 1);
    });

    test('menolak koordinat di luar rentang tanpa mengirim permintaan', () async {
      int panggilan = 0;
      final LayananUdara layanan = layananDengan((_) {
        panggilan++;
        return http.Response(contohJson, 200);
      });
      await expectLater(
        layanan.ambilKualitasUdara(lintang: 120, bujur: 0),
        throwsArgumentError,
      );
      expect(panggilan, 0);
    });

    test('isi yang bukan JSON pada kode 200 menjadi FormatException', () async {
      final LayananUdara layanan =
          layananDengan((_) => http.Response('<html>bukan json</html>', 200));
      await expectLater(
        layanan.ambilKualitasUdara(lintang: -0.5, bujur: 117.15),
        throwsFormatException,
      );
    });

    test('kode 200 dengan penanda error dianggap galat', () async {
      final LayananUdara layanan = layananDengan(
        (_) => http.Response('{"error":true,"reason":"gangguan"}', 200),
      );
      await expectLater(
        layanan.ambilKualitasUdara(lintang: -0.5, bujur: 117.15),
        throwsFormatException,
      );
    });
  });

  group('Repositori', () {
    test('membaca data saat ini dan per jam', () async {
      late http.Request terakhir;
      final RepositoriUdara repo = repoDengan((http.Request p) {
        terakhir = p;
        return http.Response(contohJson, 200);
      });

      final Udara udara = await repo.ambil(Kota.samarinda);

      expect(
        terakhir.url.queryParameters['latitude'],
        '${Kota.samarinda.lintang}',
      );
      expect(udara.saatIni.aqi, 87);
      expect(udara.saatIni.kategori, KategoriAqi.sedang);
      expect(udara.saatIni.polutan.length, 6);
      expect(udara.saatIni.polutan[0].nilai, 28.4);
      expect(udara.saatIni.polutan[1].nilai, isNull); // PM10 kosong
      // Entri per jam yang bernilai null dilewati.
      expect(udara.perJam.length, 2);
      expect(udara.perJam[1].kategori, KategoriAqi.sensitif);
    });

    test('kadar negatif dianggap tidak valid (null)', () async {
      final RepositoriUdara repo = repoDengan(
        (_) => http.Response(
          contohJson.replaceFirst('"pm2_5": 28.4', '"pm2_5": -5'),
          200,
        ),
      );
      final Udara udara = await repo.ambil(Kota.jakarta);
      expect(udara.saatIni.polutan[0].nilai, isNull);
    });

    test('melempar FormatException bila AQI tidak ada', () async {
      final RepositoriUdara repo = repoDengan(
        (_) => http.Response(
          '{"current":{"time":"x"},"hourly":{"time":[],"us_aqi":[]}}',
          200,
        ),
      );
      await expectLater(repo.ambil(Kota.jakarta), throwsFormatException);
    });

    test('tipe data yang keliru menjadi FormatException, bukan crash', () async {
      final RepositoriUdara repo = repoDengan(
        (_) => http.Response(
          '{"current":"salah","hourly":{"time":[],"us_aqi":[]}}',
          200,
        ),
      );
      await expectLater(repo.ambil(Kota.jakarta), throwsFormatException);
    });
  });

  group('UdaraViewModel', () {
    test('kode 500 menghasilkan status gagal dan pesan ramah', () async {
      final UdaraViewModel vm = UdaraViewModel(
        repositori: repoDengan((_) => http.Response('{}', 500)),
      );
      await vm.muat();
      expect(vm.status, StatusMuat.gagal);
      expect(
        vm.pesanGalat,
        'Server sedang bermasalah. Silakan coba lagi nanti.',
      );
      vm.dispose();
    });

    test('data berhasil dimuat', () async {
      final UdaraViewModel vm = UdaraViewModel(
        repositori: repoDengan((_) => http.Response(contohJson, 200)),
      );
      await vm.muat();
      expect(vm.status, StatusMuat.berhasil);
      expect(vm.udara?.saatIni.aqi, 87);
      expect(vm.diperbarui, isNotNull);
      expect(vm.kedaluwarsa, isFalse);
      vm.dispose();
    });

    test('penyegaran gagal mempertahankan data lama dan menandainya', () async {
      final Udara udara = await repoDengan(
        (_) => http.Response(contohJson, 200),
      ).ambil(Kota.jakarta);
      final UdaraViewModel vm = UdaraViewModel(
        repositori: RepoPalsu([udara, const ApiException(503)]),
      );

      await vm.muat(); // berhasil
      await vm.segarkan(); // gagal

      expect(vm.status, StatusMuat.berhasil);
      expect(vm.udara, isNotNull);
      expect(vm.kedaluwarsa, isTrue);
      expect(vm.pesanGalat, isNotEmpty);
      vm.dispose();
    });

    test('kode 429 menghasilkan pesan khusus', () {
      expect(
        pesanRamah(const ApiException(429)),
        'Permintaan terlalu sering. Mohon tunggu sebentar lalu coba lagi.',
      );
    });

    test('jawaban terlambat dari kota lama diabaikan', () async {
      final Udara udara = await repoDengan(
        (_) => http.Response(contohJson, 200),
      ).ambil(Kota.jakarta);
      final UdaraViewModel vm =
          UdaraViewModel(repositori: RepoPalsu([udara]));

      final Future<void> lama = vm.muat();
      vm.pilihKota(Kota.medan); // memulai permintaan baru
      await lama;

      expect(vm.kota, Kota.medan);
      vm.dispose();
    });
  });

  group('Cache dan penyimpanan lokal', () {
    test('data yang berhasil dimuat tersimpan dan dapat dibaca kembali', () async {
      final PenyimpananMemori simpan = PenyimpananMemori();
      final RepositoriUdara repo = RepositoriUdaraOpenMeteo(
        layanan: layananDengan((_) => http.Response(contohJson, 200)),
        penyimpanan: simpan,
      );

      await repo.ambil(Kota.bandung);
      final Udara? cache = await repo.ambilCache(Kota.bandung);

      expect(cache, isNotNull);
      expect(cache!.dariCache, isTrue);
      expect(cache.saatIni.aqi, 87);
      // Kota lain belum pernah dimuat, sehingga cache-nya kosong.
      expect(await repo.ambilCache(Kota.medan), isNull);
    });

    test('cache yang rusak dianggap tidak ada', () async {
      final PenyimpananMemori simpan = PenyimpananMemori();
      await simpan.simpanCache(Kota.jakarta, 'bukan json', DateTime.now());
      final RepositoriUdara repo = RepositoriUdaraOpenMeteo(
        layanan: layananDengan((_) => http.Response('{}', 500)),
        penyimpanan: simpan,
      );
      expect(await repo.ambilCache(Kota.jakarta), isNull);
    });

    test('tanpa koneksi, ViewModel menampilkan data tersimpan', () async {
      final UdaraViewModel vm = UdaraViewModel(
        repositori: RepoPalsu(
          [const ApiException(503)],
          cache: buatUdara(Kota.jakarta, 64, dariCache: true),
        ),
      );
      await vm.muat();

      expect(vm.status, StatusMuat.berhasil);
      expect(vm.udara?.saatIni.aqi, 64);
      expect(vm.kedaluwarsa, isTrue);
      vm.dispose();
    });

    test('kota terakhir dipulihkan saat aplikasi dibuka', () async {
      final UdaraViewModel vm = UdaraViewModel(
        repositori: RepoPalsu([buatUdara(Kota.medan, 40)]),
        penyimpanan: PenyimpananMemori(kotaTerakhir: 'medan'),
      );
      await vm.mulai();

      expect(vm.kota, Kota.medan);
      expect(vm.status, StatusMuat.berhasil);
      vm.dispose();
    });

    test('nama kota tersimpan yang tidak dikenal diabaikan', () async {
      final UdaraViewModel vm = UdaraViewModel(
        repositori: RepoPalsu([buatUdara(Kota.jakarta, 40)]),
        penyimpanan: PenyimpananMemori(kotaTerakhir: 'atlantis'),
      );
      await vm.mulai();

      expect(vm.kota, Kota.jakarta);
      vm.dispose();
    });

    test('kota yang dipilih pengguna disimpan', () async {
      final PenyimpananMemori simpan = PenyimpananMemori();
      final UdaraViewModel vm = UdaraViewModel(
        repositori: RepoPalsu([buatUdara(Kota.bandung, 40)]),
        penyimpanan: simpan,
      );
      vm.pilihKota(Kota.bandung);
      await Future<void>.delayed(Duration.zero);

      expect(await simpan.bacaKotaTerakhir(), 'bandung');
      vm.dispose();
    });
  });

  group('PeringkatViewModel', () {
    test('diurutkan dari terbersih; kota gagal berada di urutan akhir', () async {
      final PeringkatViewModel vm = PeringkatViewModel(
        repositori: RepoPerKota({
          for (final Kota k in Kota.values) k: 90,
          Kota.bandung: 40,
          Kota.medan: 70,
          Kota.jakarta: 120,
          Kota.denpasar: null, // gagal dan tanpa cache
        }),
      );
      await vm.muat();

      expect(vm.status, StatusMuat.berhasil);
      expect(vm.daftar.first.kota, Kota.bandung);
      expect(vm.terbersih?.kota, Kota.bandung);
      expect(vm.terkotor?.kota, Kota.jakarta);
      expect(vm.daftar.last.kota, Kota.denpasar);
      expect(vm.jumlahTidakTersedia, 1);
      vm.dispose();
    });

    test('semua kota gagal menghasilkan status gagal', () async {
      final PeringkatViewModel vm = PeringkatViewModel(
        repositori: RepoPerKota({for (final Kota k in Kota.values) k: null}),
      );
      await vm.muat();

      expect(vm.status, StatusMuat.gagal);
      expect(vm.pesanGalat, isNotEmpty);
      vm.dispose();
    });

    test('kota yang gagal memakai data tersimpan bila ada', () async {
      final PeringkatViewModel vm = PeringkatViewModel(
        repositori: RepoPerKota(
          {for (final Kota k in Kota.values) k: 80, Kota.surabaya: null},
          cache: {Kota.surabaya: buatUdara(Kota.surabaya, 30, dariCache: true)},
        ),
      );
      await vm.muat();

      expect(vm.jumlahTidakTersedia, 0);
      expect(vm.adaDataLama, isTrue);
      expect(vm.terbersih?.kota, Kota.surabaya);
      vm.dispose();
    });
  });
}
