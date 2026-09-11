import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// Gunakan ConsumerWidget agar widget ini bisa "mendengarkan" perubahan dari Riverpod
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch akan me-rebuild widget ini setiap kali statsProvider berubah state-nya
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Statistik'),
      ),
      // Method .when() sangat berguna untuk mapping AsyncValue menjadi Widget
      body: statsState.when(
        // Kondisi 1: SUCCESS -> Data berhasil didapatkan
        data: (stats) {
          return ListView.builder(
            itemCount: stats.length, // Menampilkan tepat 3 item sesuai data dari provider
            itemBuilder: (context, index) {
              final stat = stats[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.analytics)),
                title: Text(stat.title),
                subtitle: Text('Value: ${stat.value}'),
              );
            },
          );
        },
        // Kondisi 2: ERROR -> Terjadi kegagalan (masuk ke peluang 30% gagal)
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  // Menampilkan pesan error (menghapus prefix 'Exception: ' bawaan dart)
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  // Memanggil method retry() pada Notifier saat tombol ditekan
                  onPressed: () => ref.read(statsProvider.notifier).retry(),
                ),
              ],
            ),
          );
        },
        // Kondisi 3: LOADING -> Saat menunggu delay 2 detik
        loading: () => const Center(
          child: CircularProgressIndicator(), // Spinner
        ),
      ),
    );
  }
}