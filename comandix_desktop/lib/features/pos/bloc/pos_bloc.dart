import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos_repository.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository repository;

  PosBloc({required this.repository}) : super(PosInitial()) {
    on<PosDataLoaded>(_onLoadData);
    on<PosSectorSelected>(_onSectorSelected);
    on<PosTableSelected>(_onTableSelected);
    on<PosOrderItemsAdded>(_onOrderItemsAdded);
    on<PosOrderSentToKitchen>(_onOrderSentToKitchen);
    on<PosOrderClosed>(_onOrderClosed);
  }

  Future<void> _onLoadData(PosDataLoaded event, Emitter<PosState> emit) async {
    emit(PosLoading());
    try {
      final sectors = await repository.getSectors();
      final tables = await repository.getTables();
      final categories = await repository.getCategories();
      final products = await repository.getProducts();
      final activeOrders = await repository.getActiveOrders();

      emit(PosLoaded(
        sectors: sectors,
        tables: tables,
        categories: categories,
        products: products,
        activeOrders: activeOrders,
        selectedSectorId: sectors.isNotEmpty ? sectors.first.id : null,
      ));
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  void _onSectorSelected(PosSectorSelected event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      emit(currentState.copyWith(
        selectedSectorId: event.sectorId,
        clearSelectedTable: true,
      ));
    }
  }

  void _onTableSelected(PosTableSelected event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final table = currentState.tables.firstWhere((t) => t.id == event.tableId);
      emit(currentState.copyWith(selectedTable: table));
    }
  }

  Future<void> _onOrderItemsAdded(PosOrderItemsAdded event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        // Find existing order for table
        final existingOrderIndex = currentState.activeOrders.indexWhere((o) => o.tableId == event.tableId);
        
        String orderId;
        if (existingOrderIndex == -1) {
          // Open new order
          final newOrder = await repository.openTable(event.tableId);
          orderId = newOrder.id;
        } else {
          orderId = currentState.activeOrders[existingOrderIndex].id;
        }

        // Add items
        await repository.addItemsToOrder(orderId, event.items);
        
        // Refresh active orders
        final updatedOrders = await repository.getActiveOrders();
        emit(currentState.copyWith(activeOrders: updatedOrders));
      } catch (e) {
        // Just emit current state to clear loading or show toast (not implemented here)
        emit(currentState);
      }
    }
  }

  Future<void> _onOrderSentToKitchen(PosOrderSentToKitchen event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        await repository.sendOrderToKitchen(event.orderId);
        final updatedOrders = await repository.getActiveOrders();
        emit(currentState.copyWith(activeOrders: updatedOrders));
      } catch (e) {
        emit(currentState);
      }
    }
  }

  Future<void> _onOrderClosed(PosOrderClosed event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        await repository.closeOrder(event.orderId, event.paymentMethod);
        final updatedOrders = await repository.getActiveOrders();
        emit(currentState.copyWith(activeOrders: updatedOrders, clearSelectedTable: true));
      } catch (e) {
        emit(currentState);
      }
    }
  }
}
