import 'dart:io';

class LanPrinter {
  final String ipAddress;
  final int port;

  const LanPrinter({required this.ipAddress, required this.port});

  Future<bool> printBytes(List<int> bytes) async {
    try {
      final socket = await Socket.connect(
        ipAddress, 
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return true;
    } on SocketException catch (e) {
      print('[LanPrinter] Connection failed to $ipAddress:$port — $e');
      return false;
    }
  }
}
