import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../pos/pos_repository.dart';
import '../../../core/network/socket_client.dart';
import '../../../shared/models/order_model.dart';
import 'kds_event.dart';
import 'kds_state.dart';

class KdsBloc extends Bloc<KdsEvent, KdsState> {
  final PosRepository repository;
  final SocketClient socketClient;
  late StreamSubscription _socketSubscription;

  KdsBloc({required this.repository, required this.socketClient}) : super(KdsLoading()) {
    on<KdsStarted>(_onStarted);
    on<KdsOrderReceived>(_onOrderReceived);
    on<KdsOrderMarkedReady>(_onOrderMarkedReady);

    // Listen to real-time new kitchen orders
    _socketSubscription = socketClient.onKitchenNewOrder.listen((data) {
      final order = OrderModel.fromJson(data);
      add(KdsOrderReceived(order));
    });
  }

  Future<void> _onStarted(KdsStarted event, Emitter<KdsState> emit) async {
    try {
      final allOrders = await repository.getActiveOrders();
      // Filter only orders that are in the kitchen (or preparing if we add that status)
      final kitchenOrders = allOrders.where((o) => o.status == 'sent_to_kitchen' || o.status == 'preparing').toList();
      emit(KdsLoaded(activeKitchenOrders: kitchenOrders));
    } catch (e) {
      emit(KdsError(e.toString()));
    }
  }

  void _onOrderReceived(KdsOrderReceived event, Emitter<KdsState> emit) {
    if (state is KdsLoaded) {
      final currentState = state as KdsLoaded;
      final updatedOrders = List<OrderModel>.from(currentState.activeKitchenOrders);
      
      // Update if exists, otherwise add
      final index = updatedOrders.indexWhere((o) => o.id == event.order.id);
      if (index >= 0) {
        updatedOrders[index] = event.order;
      } else {
        updatedOrders.add(event.order);
      }
      
      emit(currentState.copyWith(activeKitchenOrders: updatedOrders));
    }
  }

  Future<void> _onOrderMarkedReady(KdsOrderMarkedReady event, Emitter<KdsState> emit) async {
    if (state is KdsLoaded) {
      final currentState = state as KdsLoaded;
      try {
        await repository.updateOrderStatus(event.orderId, 'ready');
        // Remove from KDS screen or keep it but marked ready?
        // Let's remove it for simplicity (it's done).
        final updatedOrders = currentState.activeKitchenOrders.where((o) => o.id != event.orderId).toList();
        emit(currentState.copyWith(activeKitchenOrders: updatedOrders));
      } catch (e) {
        // Handle error (maybe show a snackbar in UI, but keep state)
      }
    }
  }

  @override
  Future<void> close() {
    _socketSubscription.cancel();
    return super.close();
  }
}
