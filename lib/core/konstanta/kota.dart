/// Daftar kota kampus beserta koordinatnya.
///
/// Koordinat dipakai sebagai parameter permintaan ke API. Untuk menambah
/// kota, cukup tambahkan satu baris baru; pilihan kota di layar akan
/// menyesuaikan secara otomatis karena dibentuk dari `Kota.values`.
enum Kota {
  jakarta('Jakarta', -6.20, 106.85),
  bandung('Bandung', -6.91, 107.61),
  yogyakarta('Yogyakarta', -7.80, 110.37),
  surabaya('Surabaya', -7.25, 112.75),
  denpasar('Denpasar', -8.65, 115.22),
  samarinda('Samarinda', -0.50, 117.15),
  makassar('Makassar', -5.15, 119.43),
  medan('Medan', 3.59, 98.67);

  const Kota(this.nama, this.lintang, this.bujur);

  final String nama;
  final double lintang; // latitude, rentang -90 sampai 90
  final double bujur; // longitude, rentang -180 sampai 180
}
