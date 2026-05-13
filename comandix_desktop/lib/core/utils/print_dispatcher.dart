import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../shared/models/printer_model.dart';

class PrintDispatcher {
  static Future<void> dispatch(PrinterModel printer, String ticketText, {double paperWidth = 58.0}) async {
    if (printer.type == 'SYSTEM') {
      await _printToSystem(printer.name, ticketText, paperWidth);
    } else if (printer.type == 'LAN') {
      await _printToLan(printer.ipAddress!, printer.port ?? 9100, ticketText);
    }
  }

  static Future<void> _printToSystem(String printerName, String text, double width) async {
    final pdf = pw.Document();
    
    PdfPageFormat format;
    if (width > 200) {
      format = PdfPageFormat.a4;
    } else {
      format = PdfPageFormat(width * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: width > 200 ? 12 : 8, 
                font: pw.Font.courier(),
              ),
            ),
          );
        },
      ),
    );

    try {
      final printers = await Printing.listPrinters();
      final target = printers.firstWhere((p) => p.name == printerName);
      
      await Printing.directPrintPdf(
        printer: target,
        onLayout: (PdfPageFormat format) => pdf.save(),
      );
    } catch (e) {
      print('[PrintDispatcher] Error printing to system: $e');
    }
  }

  static Future<void> _printToLan(String ip, int port, String text) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.write(text);
      // Basic ESC/POS cut
      socket.add([0x1D, 0x56, 0x41, 0x00]); 
      await socket.flush();
      await socket.close();
    } catch (e) {
      print('[PrintDispatcher] Error printing to LAN: $e');
    }
  }
}
