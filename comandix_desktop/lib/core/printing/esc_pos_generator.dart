import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class EscPosGenerator {
  static Future<List<int>> kitchenTicket({
    required String tableName,
    required String waiterName,
    required List<Map<String, dynamic>> items,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);
    final List<int> bytes = [];

    bytes += gen.text(
      'KITCHEN',
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2),
    );
    bytes += gen.hr();
    bytes += gen.text('TABLE : $tableName', styles: const PosStyles(bold: true));
    bytes += gen.text('WAITER: $waiterName');
    bytes += gen.text('TIME  : ${_now()}');
    bytes += gen.hr();

    for (final item in items) {
      final qty = item['qty'];
      final product = item['product'];
      final notes = item['notes'];
      
      bytes += gen.text('${qty}x  $product', styles: const PosStyles(bold: true));
      if (notes != null && notes.toString().isNotEmpty) {
        bytes += gen.text('    > $notes');
      }
    }

    bytes += gen.hr();
    bytes += gen.feed(3);
    bytes += gen.cut();
    return bytes;
  }

  static String _now() {
    final t = DateTime.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
