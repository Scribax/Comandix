import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  late IO.Socket _socket;
  final String url;
  
  // Streams to expose events to the BLoCs
  final _kitchenNewOrderController = StreamController<Map<String, dynamic>>.broadcast();
  final _tableStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _printJobController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onKitchenNewOrder => _kitchenNewOrderController.stream;
  Stream<Map<String, dynamic>> get onTableStatusChanged => _tableStatusController.stream;
  Stream<Map<String, dynamic>> get onOrderUpdated => _orderUpdatedController.stream;
  Stream<Map<String, dynamic>> get onPrintJob => _printJobController.stream;

  SocketClient({required this.url});

  void connect(String restaurantId) {
    _socket = IO.io('$url/pos', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build()
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('[SocketClient] Connected to POS namespace');
      _socket.emit('joinRestaurant', {'restaurantId': restaurantId});
    });

    _socket.onDisconnect((_) => print('[SocketClient] Disconnected'));

    // Listen to NestJS events
    _socket.on('kitchen:newOrder', (data) {
      _kitchenNewOrderController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('table:statusChanged', (data) {
      _tableStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('order:updated', (data) {
      _orderUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket.on('print:job', (data) {
      _printJobController.add(Map<String, dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket.disconnect();
  }

  void dispose() {
    _kitchenNewOrderController.close();
    _tableStatusController.close();
    _orderUpdatedController.close();
  }
}
