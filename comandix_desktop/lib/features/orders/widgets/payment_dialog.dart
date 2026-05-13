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
  int splitPeople = 1;
  bool isSplitMode = false;

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
    final activeItems = widget.order.items.where((item) => !item.isVoided).toList();
    final double total = activeItems.fold(0.0, (sum, item) => sum + (item.unitPriceSnapshot * item.quantity));
    final double currentTotal = total / splitPeople;

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
          child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                
                // Total Display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isSplitMode ? 'TOTAL POR PERSONA' : 'TOTAL A PAGAR', 
                            style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 10)),
                          if (isSplitMode)
                            Text('Dividido entre $splitPeople', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        '\$${currentTotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Split Check Button
                GestureDetector(
                  onTap: () => setState(() => isSplitMode = !isSplitMode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSplitMode ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSplitMode ? const Color(0xFF3B82F6) : Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_rounded, color: isSplitMode ? const Color(0xFF3B82F6) : Colors.white38, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          isSplitMode ? 'DIVIDIR CUENTA: $splitPeople PERS.' : 'DIVIDIR CUENTA',
                          style: TextStyle(
                            color: isSplitMode ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (isSplitMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSplitButton(Icons.remove, () {
                        if (splitPeople > 1) setState(() => splitPeople--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('$splitPeople', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      ),
                      _buildSplitButton(Icons.add, () {
                        setState(() => splitPeople++);
                      }),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
  
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
                const SizedBox(height: 24),
  
                // Cash Calculator (Only if cash selected)
                if (selectedMethod == 'cash') ...[
                  TextField(
                    controller: _receivedController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF3B82F6)),
                      labelText: 'Monto Recibido',
                      labelStyle: const TextStyle(color: Colors.white38),
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: Colors.white10),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.02),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Amount Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickAmountButton('EXACTO', currentTotal),
                      _buildQuickAmountButton('1.000', 1000),
                      _buildQuickAmountButton('5.000', 5000),
                      _buildQuickAmountButton('10.000', 10000),
                      _buildQuickAmountButton('20.000', 20000),
                    ],
                  ),
                  const SizedBox(height: 24),
  
                  // Change display with better logic
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (receivedAmount >= currentTotal) 
                          ? const Color(0xFF10B981).withOpacity(0.05) 
                          : const Color(0xFFEF4444).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (receivedAmount >= currentTotal) 
                            ? const Color(0xFF10B981).withOpacity(0.2) 
                            : const Color(0xFFEF4444).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          receivedAmount >= currentTotal ? 'VUELTO' : 'FALTAN',
                          style: TextStyle(
                            color: receivedAmount >= currentTotal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '\$${(receivedAmount - currentTotal).abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: receivedAmount >= currentTotal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (selectedMethod != 'cash' || receivedAmount >= currentTotal)
                              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (selectedMethod != 'cash' || receivedAmount >= currentTotal) 
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double value) {
    return InkWell(
      onTap: () {
        setState(() {
          if (label == 'EXACTO') {
            _receivedController.text = value.toStringAsFixed(0);
          } else {
            double current = double.tryParse(_receivedController.text) ?? 0;
            _receivedController.text = (current + value).toStringAsFixed(0);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
