import 'package:flutter/material.dart';
import '../../../shared/models/table_model.dart';
import 'package:uuid/uuid.dart';

class FloorPlanController extends ChangeNotifier {
  List<TableModel> elements = [];
  String? selectedElementId;
  bool isReadOnly = false;
  bool snapToGrid = true;
  double gridSize = 20.0;

  // For Undo/Redo (simplified)
  final List<List<TableModel>> _history = [];
  int _historyIndex = -1;

  void setElements(List<TableModel> newElements) {
    elements = List.from(newElements);
    _saveToHistory();
    notifyListeners();
  }

  void selectElement(String? id) {
    selectedElementId = id;
    notifyListeners();
  }

  void updateElement(TableModel updated) {
    final index = elements.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      elements[index] = updated;
      notifyListeners();
    }
  }

  void finalizeUpdate() {
    _saveToHistory();
  }

  void addElement(String shape, String sectorId, {double? x, double? y}) {
    final newElement = TableModel(
      id: const Uuid().v4(),
      name: '${elements.length + 1}',
      status: 'free',
      shape: shape,
      type: 'table',
      posX: x ?? 200,
      posY: y ?? 200,
      width: shape == 'long_bar' ? 200 : 80,
      height: 80,
      rotation: 0,
      sectorId: sectorId,
    );
    elements.add(newElement);
    selectedElementId = newElement.id;
    _saveToHistory();
    notifyListeners();
  }

  void addWall(String sectorId, {double? x, double? y}) {
    final newElement = TableModel(
      id: const Uuid().v4(),
      name: '',
      status: 'none',
      shape: 'square',
      type: 'wall',
      posX: x ?? 200,
      posY: y ?? 200,
      width: 200,
      height: 10,
      rotation: 0,
      sectorId: sectorId,
    );
    elements.add(newElement);
    selectedElementId = newElement.id;
    _saveToHistory();
    notifyListeners();
  }

  void addDecoration(String iconName, String sectorId, {double? x, double? y}) {
    final newElement = TableModel(
      id: const Uuid().v4(),
      name: '',
      status: 'none',
      shape: 'square',
      type: 'decoration',
      icon: iconName,
      posX: x ?? 200,
      posY: y ?? 200,
      width: 60,
      height: 60,
      rotation: 0,
      zIndex: 1,
      sectorId: sectorId,
    );
    elements.add(newElement);
    selectedElementId = newElement.id;
    _saveToHistory();
    notifyListeners();
  }

  void addLabel(String sectorId, {double? x, double? y}) {
    final newElement = TableModel(
      id: const Uuid().v4(),
      name: '',
      status: 'none',
      shape: 'square',
      type: 'label',
      labelText: 'Nueva Etiqueta',
      posX: x ?? 200,
      posY: y ?? 200,
      width: 200,
      height: 50,
      rotation: 0,
      zIndex: 2,
      sectorId: sectorId,
    );
    elements.add(newElement);
    selectedElementId = newElement.id;
    _saveToHistory();
    notifyListeners();
  }

  void moveSelectionToFront() {
    if (selectedElementId != null) {
      final index = elements.indexWhere((e) => e.id == selectedElementId);
      if (index != -1) {
        final maxZ = elements.map((e) => e.zIndex).fold(0, (prev, curr) => curr > prev ? curr : prev);
        elements[index] = elements[index].copyWith(zIndex: maxZ + 1);
        notifyListeners();
      }
    }
  }

  void moveSelectionToBack() {
    if (selectedElementId != null) {
      final index = elements.indexWhere((e) => e.id == selectedElementId);
      if (index != -1) {
        final minZ = elements.map((e) => e.zIndex).fold(0, (prev, curr) => curr < prev ? curr : prev);
        elements[index] = elements[index].copyWith(zIndex: minZ - 1);
        notifyListeners();
      }
    }
  }

  void removeSelected() {
    if (selectedElementId != null) {
      elements.removeWhere((e) => e.id == selectedElementId);
      selectedElementId = null;
      _saveToHistory();
      notifyListeners();
    }
  }

  void duplicateSelected() {
    if (selectedElementId != null) {
      final selected = elements.firstWhere((e) => e.id == selectedElementId);
      final duplicated = selected.copyWith(
        id: const Uuid().v4(),
        posX: selected.posX + 20,
        posY: selected.posY + 20,
      );
      elements.add(duplicated);
      selectedElementId = duplicated.id;
      _saveToHistory();
      notifyListeners();
    }
  }

  void _saveToHistory() {
    // Basic undo/redo logic
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(List.from(elements));
    _historyIndex++;
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      elements = List.from(_history[_historyIndex]);
      notifyListeners();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      elements = List.from(_history[_historyIndex]);
      notifyListeners();
    }
  }
}
