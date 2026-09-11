import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatData {
  final String title;
  final int value;
  StatData(this.title, this.value);
}

// Menggunakan Notifier biasa agar Exception lebih mudah dikurung dan di-test
class StatsNotifier extends Notifier<AsyncValue<List<StatData>>> {
  @override
  AsyncValue<List<StatData>> build() {
    // Jalankan proses ambil data di background saat provider dibuat
    _fetchStats();
    // Langsung kembalikan status Loading
    return const AsyncValue.loading();
  }

  Future<void> _fetchStats() async {
    // AsyncValue.guard secara otomatis menangkap hasil sukses (Data) 
    // ATAUPUN kegagalan (Error) tanpa membocorkannya ke Test Runner.
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulasi error 30%
      if (Random().nextDouble() < 0.3) {
        throw Exception('Gagal mengambil data statistik. Silakan coba lagi.');
      }
      
      // Jika sukses (70%)
      return [
        StatData('Total Pengguna Aktif', 1250),
        StatData('Total Pendapatan', 50000),
        StatData('Tingkat Konversi', 12),
      ];
    });
  }

  // Method untuk dipanggil dari UI saat tombol "Coba Lagi" ditekan
  void retry() {
    state = const AsyncValue.loading(); // Kembalikan ke UI spinner
    _fetchStats(); // Jalankan ulang
  }
}

// Provider global yang di-consume oleh UI
final statsProvider = NotifierProvider<StatsNotifier, AsyncValue<List<StatData>>>(() {
  return StatsNotifier();
});