import 'package:equatable/equatable.dart';
import '../../../shared/models/order_model.dart';

abstract class KdsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class KdsLoading extends KdsState {}

class KdsLoaded extends KdsState {
  final List<OrderModel> activeKitchenOrders;

  KdsLoaded({required this.activeKitchenOrders});

  @override
  List<Object?> get props => [activeKitchenOrders];

  KdsLoaded copyWith({
    List<OrderModel>? activeKitchenOrders,
  }) {
    return KdsLoaded(
      activeKitchenOrders: activeKitchenOrders ?? this.activeKitchenOrders,
    );
  }
}

class KdsError extends KdsState {
  final String message;
  KdsError(this.message);

  @override
  List<Object?> get props => [message];
}
