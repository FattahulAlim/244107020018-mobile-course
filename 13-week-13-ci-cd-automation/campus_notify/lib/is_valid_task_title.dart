/// Fungsi validasi judul tugas/catatan berdasarkan aturan bisnis:
/// Judul harus berisi teks setelah spasi di awal dan akhir diabaikan.
bool isValidTaskTitle(String value) {
  return value.trim().isNotEmpty;
}

/// Validasi judul dengan batasan panjang karakter maksimum.
bool isValidTaskTitleWithLimit(String value, {int maxLength = 100}) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty && trimmed.length <= maxLength;
}
