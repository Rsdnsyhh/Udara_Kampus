/// Menambahkan angka nol di depan agar selalu dua digit (misalnya 7 -> "07").
/// Dipakai untuk menampilkan jam dan menit.
String duaDigit(int angka) => angka.toString().padLeft(2, '0');

/// Memformat kadar polutan untuk ditampilkan.
///
/// Nilai besar dibulatkan karena desimalnya tidak lagi bermakna, sedangkan
/// nilai kecil diberi satu desimal. Nilai kosong (null) ditampilkan sebagai
/// tanda "-" agar tampilan tidak menunjukkan angka yang menyesatkan.
String formatAngka(double? nilai) {
  if (nilai == null) return '-';
  return nilai >= 100 ? nilai.round().toString() : nilai.toStringAsFixed(1);
}
