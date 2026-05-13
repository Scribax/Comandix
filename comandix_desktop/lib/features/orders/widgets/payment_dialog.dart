import 'package:flutter/material.dart';
import '../../../shared/models/order_model.dart';
import 'dart:ui';

class PaymentDialog extends StatefulWidget {
  final OrderModel order;
  final Function(String method) onConfirm;

  const PaymentDialog({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String selectedMethod = 'cash';
  final TextEditingController _receivedController = TextEditingController();
  double receivedAmount = 0;

  @override
  void initState() {
    super.initState();
    _receivedController.addListener(() {
      setState(() {
        receivedAmount = double.tryParse(_receivedController.text) ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double total = widget.order.total;
    final double change = receivedAmount > total ? receivedAmount - total : 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Finalizar Pago',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Mesa ${widget.order.table?.name ?? '??'}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // Total Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Methods
              Row(
                children: [
                  _buildMethodOption('cash', Icons.payments_rounded, 'Efectivo'),
                  const SizedBox(width: 12),
                  _buildMethodOption('card', Icons.credit_card_rounded, 'Tarjeta'),
                  const SizedBox(width: 12),
                  _buildMethodOption('qr', Icons.qr_code_scanner_rounded, 'QR / MP'),
                ],
              ),
              const SizedBox(height: 32),

              // Cash Calculator (Only if cash selected)
              if (selectedMethod == 'cash') ...[
                TextField(
                  controller: _receivedController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Monto Recibido',
                    labelStyle: const TextStyle(color: Colors.white38),
                    hintText: '0.00',
                    hintStyle: const TextStyle(color: Colors.white10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('VUELTO:', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${change.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: change > 0 ? const Color(0xFF10B981) : Colors.white24,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        foregroundColor: Colors.white54,
                      ),
                      child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (selectedMethod != 'cash' || receivedAmount >= total) 
                        ? () => widget.onConfirm(selectedMethod) 
                        : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('CONFIRMAR PAGO', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String id, IconData icon, String label) {
    bool isSelected = selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF3B82F6) : Colors.white38),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
