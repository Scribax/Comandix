import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos_repository.dart';
import '../../../core/network/socket_client.dart';
import '../../../shared/models/order_item_model.dart';
import 'pos_event.dart';
import 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository repository;
  final SocketClient socketClient;
  late StreamSubscription _orderUpdatedSubscription;
  late StreamSubscription _tableStatusSubscription;

  PosBloc({required this.repository, required this.socketClient}) : super(PosInitial()) {
    on<PosDataLoaded>(_onLoadData);
    on<PosSectorSelected>(_onSectorSelected);
    on<PosTableSelected>(_onTableSelected);
    on<PosCategorySelected>(_onCategorySelected);
    on<PosProductTapped>(_onProductTapped);
    on<PosDraftItemRemoved>(_onDraftItemRemoved);
    on<PosOrderItemsAdded>(_onOrderItemsAdded);
    on<PosOrderSentToKitchen>(_onOrderSentToKitchen);
    on<PosOrderClosed>(_onOrderClosed);
    on<PosViewChanged>(_onViewChanged);
    on<PosItemVoided>(_onItemVoided);
    on<PosSectorCreated>(_onSectorCreated);
    on<PosItemNoteUpdated>(_onItemNoteUpdated);
    on<PosCategoryCreated>(_onCategoryCreated);
    on<PosCategoryUpdated>(_onCategoryUpdated);
    on<PosCategoryDeleted>(_onCategoryDeleted);
    on<PosProductCreated>(_onProductCreated);
    on<PosProductUpdated>(_onProductUpdated);
    on<PosProductDeleted>(_onProductDeleted);
    on<PosProductionSectorCreated>(_onProductionSectorCreated);
    on<PosProductionSectorUpdated>(_onProductionSectorUpdated);
    on<PosProductionSectorDeleted>(_onProductionSectorDeleted);
    on<PosPrinterCreated>(_onPrinterCreated);
    on<PosPrinterUpdated>(_onPrinterUpdated);
    on<PosPrinterDeleted>(_onPrinterDeleted);
    on<PosPrinterTestRequested>(_onPrinterTestRequested);

    // Listen to real-time events
    _orderUpdatedSubscription = socketClient.onOrderUpdated.listen((_) {
      // Just reload the data to sync orders
      add(PosDataLoaded());
    });

    _tableStatusSubscription = socketClient.onTableStatusChanged.listen((_) {
      // Just reload the data to sync tables
      add(PosDataLoaded());
    });
  }

  @override
  Future<void> close() {
    _orderUpdatedSubscription.cancel();
    _tableStatusSubscription.cancel();
    return super.close();
  }

  void _onViewChanged(PosViewChanged event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      emit(currentState.copyWith(currentViewIndex: event.viewIndex));
    }
  }

  Future<void> _onItemVoided(PosItemVoided event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        await repository.voidItem(event.orderId, event.itemId);
        final updatedOrders = await repository.getActiveOrders();
        emit(currentState.copyWith(activeOrders: updatedOrders));
      } catch (e) {
        emit(currentState);
      }
    }
  }

  Future<void> _onLoadData(PosDataLoaded event, Emitter<PosState> emit) async {
    final currentSectorId = (state is PosLoaded) ? (state as PosLoaded).selectedSectorId : null;
    final currentSelectedTable = (state is PosLoaded) ? (state as PosLoaded).selectedTable : null;
    final currentCategoryId = (state is PosLoaded) ? (state as PosLoaded).selectedCategoryId : null;
    final currentViewIndex = (state is PosLoaded) ? (state as PosLoaded).currentViewIndex : 0;
    final currentDrafts = (state is PosLoaded) ? (state as PosLoaded).draftItems : <String, List<OrderItemModel>>{};

    emit(PosLoading());
    try {
      final sectors = await repository.getSectors();
      final tables = await repository.getTables();
      final categories = await repository.getCategories();
      final products = await repository.getProducts();
      final productionSectors = await repository.getProductionSectors();
      final printers = await repository.getPrinters();
      final activeOrders = await repository.getActiveOrders();
      final dashboardStats = await repository.getDashboardStats();

      emit(PosLoaded(
        sectors: sectors,
        tables: tables,
        categories: categories,
        products: products,
        productionSectors: productionSectors,
        printers: printers,
        activeOrders: activeOrders,
        selectedSectorId: currentSectorId ?? (sectors.isNotEmpty ? sectors.first.id : null),
        selectedCategoryId: currentCategoryId ?? (categories.isNotEmpty ? categories.first.id : null),
        selectedTable: currentSelectedTable,
        currentViewIndex: currentViewIndex,
        draftItems: currentDrafts,
        dashboardStats: dashboardStats,
      ));
    } catch (e) {
      if (e.toString().contains('401')) {
        emit(PosError('SESIÓN EXPIRADA: Por favor vuelve a iniciar sesión para continuar.'));
      } else {
        emit(PosError(e.toString()));
      }
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
        final updatedTables = await repository.getTables();
        emit(currentState.copyWith(activeOrders: updatedOrders, tables: updatedTables));
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
        final updatedTables = await repository.getTables();
        final updatedDrafts = Map<String, List<OrderItemModel>>.from(currentState.draftItems);
        updatedDrafts.remove(event.tableId);
        
        emit(currentState.copyWith(
          activeOrders: updatedOrders,
          tables: updatedTables,
          draftItems: updatedDrafts,
        ));
      } catch (e) {
        emit(PosError('Error al enviar comanda: ${e.toString()}'));
        // Return to loaded state after showing error
        add(PosDataLoaded());
      }
    }
  }

  Future<void> _onOrderClosed(PosOrderClosed event, Emitter<PosState> emit) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      try {
        await repository.closeOrder(event.orderId, event.paymentMethod);
        
        // Small delay to ensure DB consistency before refreshing
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Refresh both orders and tables to sync UI
        final updatedOrders = await repository.getActiveOrders();
        final updatedTables = await repository.getTables();
        emit(currentState.copyWith(
          activeOrders: updatedOrders, 
          tables: updatedTables,
          clearSelectedTable: true
        ));
      } catch (e) {
        emit(currentState);
      }
    }
  }

  Future<void> _onSectorCreated(PosSectorCreated event, Emitter<PosState> emit) async {
    try {
      await repository.createSector(event.name);
      add(PosDataLoaded());
    } catch (e) {
      // Handle error
    }
  }

  void _onItemNoteUpdated(PosItemNoteUpdated event, Emitter<PosState> emit) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final currentDrafts = Map<String, List<OrderItemModel>>.from(currentState.draftItems);
      final tableDraft = List<OrderItemModel>.from(currentDrafts[event.tableId] ?? []);
      
      if (event.index < tableDraft.length) {
        final existing = tableDraft[event.index];
        tableDraft[event.index] = OrderItemModel(
          id: existing.id,
          orderId: existing.orderId,
          productId: existing.productId,
          product: existing.product,
          quantity: existing.quantity,
          unitPriceSnapshot: existing.unitPriceSnapshot,
          productNameSnapshot: existing.productNameSnapshot,
          notes: event.note,
        );
        currentDrafts[event.tableId] = tableDraft;
        emit(currentState.copyWith(draftItems: currentDrafts));
      }
    }
  }

  Future<void> _onCategoryCreated(PosCategoryCreated event, Emitter<PosState> emit) async {
    try {
      await repository.createCategory(event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onCategoryUpdated(PosCategoryUpdated event, Emitter<PosState> emit) async {
    try {
      await repository.updateCategory(event.id, event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onCategoryDeleted(PosCategoryDeleted event, Emitter<PosState> emit) async {
    try {
      await repository.deleteCategory(event.id);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductCreated(PosProductCreated event, Emitter<PosState> emit) async {
    try {
      await repository.createProduct(event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductUpdated(PosProductUpdated event, Emitter<PosState> emit) async {
    try {
      await repository.updateProduct(event.id, event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductDeleted(PosProductDeleted event, Emitter<PosState> emit) async {
    try {
      await repository.deleteProduct(event.id);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductionSectorCreated(PosProductionSectorCreated event, Emitter<PosState> emit) async {
    try {
      await repository.createProductionSector(event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductionSectorUpdated(PosProductionSectorUpdated event, Emitter<PosState> emit) async {
    try {
      await repository.updateProductionSector(event.id, event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onProductionSectorDeleted(PosProductionSectorDeleted event, Emitter<PosState> emit) async {
    try {
      await repository.deleteProductionSector(event.id);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onPrinterCreated(PosPrinterCreated event, Emitter<PosState> emit) async {
    try {
      await repository.createPrinter(event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onPrinterUpdated(PosPrinterUpdated event, Emitter<PosState> emit) async {
    try {
      await repository.updatePrinter(event.id, event.data);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onPrinterDeleted(PosPrinterDeleted event, Emitter<PosState> emit) async {
    try {
      await repository.deletePrinter(event.id);
      add(PosDataLoaded());
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  Future<void> _onPrinterTestRequested(PosPrinterTestRequested event, Emitter<PosState> emit) async {
    try {
      await repository.testPrinter(event.id);
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }
}
