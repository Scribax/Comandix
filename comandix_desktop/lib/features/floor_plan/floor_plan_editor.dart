import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'floor_plan_controller.dart';
import 'widgets/canvas_element.dart';
import 'widgets/editor_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../../shared/models/sector_model.dart';
import 'dart:ui';

class FloorPlanEditor extends StatefulWidget {
  final SectorModel sector;
  final List<dynamic> initialTables;
  final Function(List<dynamic> tables) onSave;

  const FloorPlanEditor({
    super.key,
    required this.sector,
    required this.initialTables,
    required this.onSave,
  });

  @override
  State<FloorPlanEditor> createState() => _FloorPlanEditorState();
}

class _FloorPlanEditorState extends State<FloorPlanEditor> {
  late FloorPlanController _controller;
  final TransformationController _transformationController = TransformationController();
  
  // Selective pan control without full rebuilds
  final ValueNotifier<bool> _panEnabled = ValueNotifier<bool>(true);
  
  // Accumulators for smooth dragging with snap-to-grid
  double _dragTotalX = 0;
  double _dragTotalY = 0;

  @override
  void initState() {
    super.initState();
    _controller = FloorPlanController();
    _controller.setElements(widget.initialTables.cast());
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _panEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // 1. Mesh Gradient Background
            _buildBackground(),

            // 2. Main Canvas Area
            Consumer<FloorPlanController>(
              builder: (context, controller, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _panEnabled,
                  builder: (context, isPanEnabled, child) {
                    return InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(3000),
                      minScale: 0.1,
                      maxScale: 2.5,
                      panEnabled: isPanEnabled,
                      child: Stack(
                        children: [
                          // Grid lines (sutil)
                          _buildGrid(),
                          
                          // Elements
                          ...([...controller.elements]..sort((a, b) => a.zIndex.compareTo(b.zIndex))).map((element) {
                            return CanvasElement(
                              element: element,
                              isSelected: controller.selectedElementId == element.id,
                              isReadOnly: controller.isReadOnly,
                              onTap: () => controller.selectElement(element.id),
                              onDragStart: () {
                                _panEnabled.value = false; // Silence background pan
                                _dragTotalX = element.posX;
                                _dragTotalY = element.posY;
                              },
                              onDrag: (delta) {
                                final double scale = _transformationController.value.getMaxScaleOnAxis();
                                
                                // Accumulate raw movement
                                _dragTotalX += (delta.dx / scale);
                                _dragTotalY += (delta.dy / scale);
                                
                                double finalX = _dragTotalX;
                                double finalY = _dragTotalY;

                                if (controller.snapToGrid) {
                                  finalX = (finalX / controller.gridSize).round() * controller.gridSize;
                                  finalY = (finalY / controller.gridSize).round() * controller.gridSize;
                                }
                                
                                // Only update if the snapped position actually changed
                                if (finalX != element.posX || finalY != element.posY) {
                                  controller.updateElement(element.copyWith(
                                    posX: finalX,
                                    posY: finalY,
                                  ));
                                }
                              },
                              onDragEnd: () {
                                _panEnabled.value = true; // Restore background pan
                                controller.finalizeUpdate();
                              },
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // 3. UI Overlays
            
            // Header
            Positioned(
              top: 40,
              left: 40,
              child: _buildHeader(),
            ),

            // Toolbar
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: EditorToolbar(
                  controller: _controller, 
                  sectorId: widget.sector.id,
                  transformationController: _transformationController,
                ),
              ),
            ),

            // Properties Panel (Right)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Consumer<FloorPlanController>(
                builder: (context, controller, _) => PropertyPanel(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: AppColors.background),
        Positioned(
          top: -200,
          right: -200,
          child: _buildBlurCircle(AppColors.accent.withOpacity(0.1), 600),
        ),
        Positioned(
          bottom: -200,
          left: -100,
          child: _buildBlurCircle(const Color(0xFF8B5CF6).withOpacity(0.1), 500),
        ),
      ],
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGrid() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GridPainter(gridSize: _controller.gridSize),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editor de Plano',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            Text(
              widget.sector.name,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(width: 40),
        ElevatedButton.icon(
          onPressed: () => widget.onSave(_controller.elements),
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Guardar Cambios'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize;
  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < 5000; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, 5000), paint);
      canvas.drawLine(Offset(0, i), Offset(5000, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
