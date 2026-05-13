import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos_repository.dart';
import '../../../shared/models/order_item_model.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository repository;

  PosBloc({required this.repository}) : super(PosInitial()) {
    on<PosDataLoaded>(_onLoadData);
    on<PosSectorSelected>(_onSectorSelected);
    on<PosTableSelected>(_onTableSelected);
    on<PosCategorySelected>(_onCategorySelected);
    on<PosProductTapped>(_onProductTapped);
    on<PosDraftItemRemoved>(_onDraftItemRemoved);
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
        selectedCategoryId: categories.isNotEmpty ? categories.first.id : null,
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

  void _onCategorySelected(PosCategorySelected event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      emit(currentState.copyWith(selectedCategoryId: event.categoryId));
    }
  }

  void _onProductTapped(PosProductTapped event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final product = currentState.products.firstWhere((p) => p.id == event.productId);
      
      final currentDrafts = Map<String, List<OrderItemModel>>.from(currentState.draftItems);
      final tableDraft = List<OrderItemModel>.from(currentDrafts[event.tableId] ?? []);
      
      // Check if already in draft
      final existingIndex = tableDraft.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        final existing = tableDraft[existingIndex];
        tableDraft[existingIndex] = OrderItemModel(
          id: existing.id,
          orderId: existing.orderId,
          productId: existing.productId,
          product: existing.product,
          quantity: existing.quantity + 1,
          unitPriceSnapshot: existing.unitPriceSnapshot,
          productNameSnapshot: existing.productNameSnapshot,
          notes: existing.notes,
        );
      } else {
        tableDraft.add(OrderItemModel(
          id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
          orderId: '',
          productId: product.id,
          product: product,
          quantity: 1,
          unitPriceSnapshot: product.price,
          productNameSnapshot: product.name,
        ));
      }
      
      currentDrafts[event.tableId] = tableDraft;
      emit(currentState.copyWith(draftItems: currentDrafts));
    }
  }

  void _onDraftItemRemoved(PosDraftItemRemoved event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final currentDrafts = Map<String, List<OrderItemModel>>.from(currentState.draftItems);
      final tableDraft = List<OrderItemModel>.from(currentDrafts[event.tableId] ?? []);
      
      if (event.index < tableDraft.length) {
        tableDraft.removeAt(event.index);
        currentDrafts[event.tableId] = tableDraft;
        emit(currentState.copyWith(draftItems: currentDrafts));
      }
    }
  }

  Future<void> _onOrderItemsAdded(PosOrderItemsAdded event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        final existingOrderIndex = currentState.activeOrders.indexWhere((o) => o.tableId == event.tableId);
        String orderId;
        if (existingOrderIndex == -1) {
          final newOrder = await repository.createOrder(event.tableId);
          orderId = newOrder.id;
        } else {
          orderId = currentState.activeOrders[existingOrderIndex].id;
        }

        await repository.addItemsToOrder(orderId, event.items);
        final updatedOrders = await repository.getActiveOrders();
        emit(currentState.copyWith(activeOrders: updatedOrders));
      } catch (e) {
        emit(currentState);
      }
    }
  }

  Future<void> _onOrderSentToKitchen(PosOrderSentToKitchen event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        final existingOrderIndex = currentState.activeOrders.indexWhere((o) => o.tableId == event.tableId);
        
        String orderId;
        if (existingOrderIndex == -1) {
          // 1. Create order
          final newOrder = await repository.createOrder(event.tableId);
          orderId = newOrder.id;
        } else {
          orderId = currentState.activeOrders[existingOrderIndex].id;
        }

        // 2. Add draft items if any
        final draftItems = currentState.draftItems[event.tableId] ?? [];
        if (draftItems.isNotEmpty) {
          await repository.addItemsToOrder(orderId, draftItems.map((i) => {
            'productId': i.productId,
            'quantity': i.quantity,
            'unitPriceSnapshot': i.unitPriceSnapshot,
            'productNameSnapshot': i.productNameSnapshot,
          }).toList());
        }

        // 3. Update status to sent_to_kitchen
        await repository.updateOrderStatus(orderId, 'sent_to_kitchen');
        
        // 4. Refresh & Clear Draft
        final updatedOrders = await repository.getActiveOrders();
        final updatedDrafts = Map<String, List<OrderItemModel>>.from(currentState.draftItems);
        updatedDrafts.remove(event.tableId);
        
        emit(currentState.copyWith(
          activeOrders: updatedOrders,
          draftItems: updatedDrafts,
        ));
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
