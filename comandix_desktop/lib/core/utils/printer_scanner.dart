import 'dart:io';
import 'dart:async';

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

  static Stream<String> discoverPrinters() async* {
    final localIp = await getLocalIp();
    if (localIp == null) return;

    final String subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    
    // Scan all 254 IPs in parallel with a timeout
    final List<Future<String?>> tasks = [];
    
    for (int i = 1; i <= 254; i++) {
      final String targetIp = '$subnet.$i';
      tasks.add(_checkPrinter(targetIp));
    }

    // We yield results as they come
    for (var task in tasks) {
      final result = await task;
      if (result != null) yield result;
    }
  }

  static Future<String?> _checkPrinter(String ip) async {
    try {
      final socket = await Socket.connect(ip, 9100, timeout: const Duration(milliseconds: 700));
      await socket.close();
      return ip;
    } catch (_) {
      return null;
    }
  }
}
