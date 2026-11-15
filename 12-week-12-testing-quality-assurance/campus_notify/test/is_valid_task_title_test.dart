import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/is_valid_task_title.dart';

void main() {
  group('isValidTaskTitle', () {
    test('menerima judul yang berisi teks', () {
      // Arrange
      const title = 'Belajar Flutter';

      // Act
      final result = isValidTaskTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('menolak teks kosong atau hanya spasi', () {
      // Arrange & Act & Assert
      expect(isValidTaskTitle(''), isFalse);
      expect(isValidTaskTitle('   '), isFalse);
    });

    test('menerima judul dengan spasi di awal atau akhir yang memiliki teks', () {
      // Arrange
      const title = '  Pengujian Kualitas Perangkat Lunak  ';

      // Act & Assert
      expect(isValidTaskTitle(title), isTrue);
    });

    test('menolak karakter whitespace escape seperti tab dan newline murni', () {
      expect(isValidTaskTitle('\t\n  \r\n'), isFalse);
    });

    test('menerima teks alfanumerik dan simbol unicode/emoji', () {
      expect(isValidTaskTitle('📝 Tugas 12: Testing & QA'), isTrue);
    });
  });

  group('isValidTaskTitleWithLimit', () {
    test('menerima teks yang panjangnya dalam batas maksimum', () {
      expect(isValidTaskTitleWithLimit('Catatan Singkat', maxLength: 50), isTrue);
    });

    test('menolak teks yang melebihi batas panjang maksimum', () {
      final longTitle = 'X' * 105;
      expect(isValidTaskTitleWithLimit(longTitle, maxLength: 100), isFalse);
    });
  });
}
