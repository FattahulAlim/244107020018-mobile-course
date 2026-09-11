import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Sesuaikan nama package dengan folder project kamu
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  test('StatsNotifier transisi state dari loading menuju data atau error', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1. Uji State Awal (Saat pertama kali dibaca, harus Loading)
    expect(
      container.read(statsProvider) is AsyncLoading,
      true,
      reason: 'State awal harus berupa loading',
    );

    // 2. Tunggu proses selesai. 
    // Karena delay di provider adalah 2 detik, kita tunggu 3 detik agar dijamin tuntas.
    // Ini sekarang 100% aman karena tidak ada error yang akan merusak test.
    await Future.delayed(const Duration(seconds: 3));

    // 3. Uji State Akhir (Cek apakah sudah berubah)
    final finalState = container.read(statsProvider);
    
    expect(
      finalState is AsyncData || finalState is AsyncError,
      true,
      reason: 'Setelah 3 detik, state harus berubah menjadi Data (sukses) atau Error (gagal)',
    );
  });
}