import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../floor_plan_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class EditorToolbar extends StatelessWidget {
  final FloorPlanController controller;
  final String sectorId;
  final TransformationController transformationController;

  const EditorToolbar({
    super.key, 
    required this.controller, 
    required this.sectorId,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    // Helper to get center of current view
    Offset getCenter() {
      final matrix = transformationController.value;
      final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
      final size = MediaQuery.of(context).size;
      final viewportCenter = Offset(size.width / 2, size.height / 2);
      final transformedCenter = inverse.transform3(Vector3(viewportCenter.dx, viewportCenter.dy, 0));
      return Offset(transformedCenter.x - 40, transformedCenter.y - 40); // Offset by half average item size
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTool(Icons.crop_square, 'Mesa', () {
                final pos = getCenter();
                controller.addElement('square', sectorId, x: pos.dx, y: pos.dy);
              }),
              _buildTool(Icons.circle_outlined, 'Circular', () {
                final pos = getCenter();
                controller.addElement('circle', sectorId, x: pos.dx, y: pos.dy);
              }),
              _buildTool(Icons.view_kanban_outlined, 'Barra', () {
                final pos = getCenter();
                controller.addElement('long_bar', sectorId, x: pos.dx, y: pos.dy);
              }),
              _buildTool(Icons.door_sliding_outlined, 'Pared', () {
                final pos = getCenter();
                controller.addWall(sectorId, x: pos.dx, y: pos.dy);
              }),
              _buildTool(Icons.text_fields, 'Texto', () {
                final pos = getCenter();
                controller.addLabel(sectorId, x: pos.dx, y: pos.dy);
              }),
              _buildTool(Icons.category_outlined, 'Extras', () {
                final pos = getCenter();
                _showIconPicker(context, (icon) {
                  controller.addDecoration(icon, sectorId, x: pos.dx, y: pos.dy);
                });
              }),
              const VerticalDivider(color: AppColors.glassBorder, indent: 8, endIndent: 8),
              _buildTool(Icons.undo, 'Undo', controller.undo),
              _buildTool(Icons.redo, 'Redo', controller.redo),
              const VerticalDivider(color: AppColors.glassBorder, indent: 8, endIndent: 8),
              _buildTool(
                controller.isReadOnly ? Icons.edit : Icons.remove_red_eye, 
                controller.isReadOnly ? 'Editar' : 'Vista', 
                () {
                  controller.isReadOnly = !controller.isReadOnly;
                  controller.notifyListeners();
                }
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5);
  }

  void _showIconPicker(BuildContext context, Function(String) onSelected) {
    final icons = {
      'wc': Icons.wc,
      'male': Icons.male,
      'female': Icons.female,
      'kitchen': Icons.soup_kitchen,
      'restaurant': Icons.restaurant,
      'coffee': Icons.coffee,
      'pizza': Icons.local_pizza,
      'cake': Icons.cake,
      'bar': Icons.local_bar,
      'exit': Icons.exit_to_app,
      'emergency': Icons.emergency,
      'danger': Icons.warning,
      'fire': Icons.fire_extinguisher,
      'wifi': Icons.wifi,
      'medical': Icons.medical_services,
      'parking': Icons.local_parking,
      'no_smoking': Icons.smoke_free,
      'delivery': Icons.delivery_dining,
      'stairs': Icons.stairs,
      'dj': Icons.album,
      'pool': Icons.pool,
      'entrance': Icons.login,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Añadir Elemento Decorativo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                children: icons.entries.map((e) => IconButton(
                  icon: Icon(e.value, color: Colors.white70, size: 32),
                  onPressed: () {
                    onSelected(e.key);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTool(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class PropertyPanel extends StatelessWidget {
  final FloorPlanController controller;

  const PropertyPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedElementId == null 
        ? null 
        : controller.elements.firstWhere((e) => e.id == controller.selectedElementId);

    if (selected == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Propiedades', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => controller.selectElement(null),
                    )
                  ],
                ),
                const Divider(color: AppColors.glassBorder, height: 32),
                
                _buildField(
                  selected.type == 'label' ? 'Texto Etiqueta' : 'Nombre', 
                  selected.type == 'label' ? (selected.labelText ?? '') : selected.name, 
                  (val) {
                    if (selected.type == 'label') {
                      controller.updateElement(selected.copyWith(labelText: val));
                    } else {
                      controller.updateElement(selected.copyWith(name: val));
                    }
                  }
                ),
                
                const SizedBox(height: 16),
                const Text('Color Personalizado', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildColorDot(null, selected.color == null, () => controller.updateElement(selected.copyWith(color: null))),
                    _buildColorDot('#00F0FF', selected.color == '#00F0FF', () => controller.updateElement(selected.copyWith(color: '#00F0FF'))),
                    _buildColorDot('#10B981', selected.color == '#10B981', () => controller.updateElement(selected.copyWith(color: '#10B981'))),
                    _buildColorDot('#F59E0B', selected.color == '#F59E0B', () => controller.updateElement(selected.copyWith(color: '#F59E0B'))),
                    _buildColorDot('#EF4444', selected.color == '#EF4444', () => controller.updateElement(selected.copyWith(color: '#EF4444'))),
                    _buildColorDot('#8B5CF6', selected.color == '#8B5CF6', () => controller.updateElement(selected.copyWith(color: '#8B5CF6'))),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Dimensiones', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Row(
                  children: [
                    Expanded(child: _buildSlider('Ancho', selected.width, 2, 800, (val) {
                      controller.updateElement(selected.copyWith(width: val));
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSlider('Alto', selected.height, 2, 800, (val) {
                      controller.updateElement(selected.copyWith(height: val));
                    })),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Capas (Orden)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.moveSelectionToFront,
                        icon: const Icon(Icons.flip_to_front, size: 14),
                        label: const Text('Frente', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.moveSelectionToBack,
                        icon: const Icon(Icons.flip_to_back, size: 14),
                        label: const Text('Fondo', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSlider('Rotación', selected.rotation, 0, 360, (val) {
                  controller.updateElement(selected.copyWith(rotation: val));
                }),

                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(Icons.copy, 'Duplicar', controller.duplicateSelected, AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(Icons.delete_outline, 'Borrar', controller.removeSelected, AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  Widget _buildField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildColorDot(String? hex, bool isSelected, VoidCallback onTap) {
    final color = hex != null ? Color(int.parse(hex.replaceFirst('#', '0xFF'))) : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: hex == null ? Colors.white10 : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (hex != null) BoxShadow(color: color.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        child: hex == null ? const Icon(Icons.close, size: 14, color: Colors.white54) : null,
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withOpacity(0.2),
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (val) {
              onChanged(val);
              controller.finalizeUpdate(); // Save state after slider move
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
