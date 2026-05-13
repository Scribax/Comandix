import 'dart:io';
import 'dart:async';
import 'package:printing/printing.dart';

class DiscoveredPrinter {
  final String name;
  final String? ip;
  final String type; // 'LAN' or 'SYSTEM'

  DiscoveredPrinter({required this.name, this.ip, required this.type});
}

class PrinterScanner {
  static Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  static Stream<DiscoveredPrinter> discoverPrinters() async* {
    // 1. Discover System Printers (USB, etc)
    try {
      final systemPrinters = await Printing.listPrinters();
      for (var printer in systemPrinters) {
        yield DiscoveredPrinter(
          name: printer.name,
          type: 'SYSTEM',
        );
      }
    } catch (_) {}

    // 2. Discover LAN Printers
    final localIp = await getLocalIp();
    if (localIp == null) return;

    final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    
    // Scan all 254 IPs in parallel
    final List<Future<DiscoveredPrinter?>> tasks = [];
    for (int i = 1; i <= 254; i++) {
      final String targetIp = '$subnet.$i';
      tasks.add(_checkPrinter(targetIp));
    }

    for (var task in tasks) {
      final result = await task;
      if (result != null) yield result;
    }
  }

  static Future<DiscoveredPrinter?> _checkPrinter(String ip) async {
    try {
      final socket = await Socket.connect(ip, 9100, timeout: const Duration(milliseconds: 500));
      await socket.close();
      return DiscoveredPrinter(
        name: 'Impresora en $ip',
        ip: ip,
        type: 'LAN',
      );
    } catch (_) {
      return null;
    }
  }
}
