import 'dart:async';
import '../models/command.dart';

/// Service for managing command history to enable undo/redo functionality
class CommandHistoryService {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int _maxHistorySize;

  final StreamController<void> _historyChangedController =
      StreamController<void>.broadcast();

  /// Stream that emits when history state changes
  Stream<void> get historyChanged => _historyChangedController.stream;

  /// Creates a new CommandHistoryService
  /// 
  /// [maxHistorySize] limits the number of commands stored (default: 50)
  CommandHistoryService({int maxHistorySize = 50})
      : _maxHistorySize = maxHistorySize;

  /// Executes a command and adds it to the history
  void executeCommand(Command command) {
    command.execute();
    _undoStack.add(command);
    
    // Limit stack size
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    
    // Clear redo stack when new command is executed
    _redoStack.clear();
    
    _notifyHistoryChanged();
  }

  /// Undoes the last command
  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }
    
    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);
    
    _notifyHistoryChanged();
    return true;
  }

  /// Redoes the last undone command
  bool redo() {
    if (_redoStack.isEmpty) {
      return false;
    }
    
    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);
    
    _notifyHistoryChanged();
    return true;
  }

  /// Checks if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Checks if redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Gets the description of the next command to undo
  String? get nextUndoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;

  /// Gets the description of the next command to redo
  String? get nextRedoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  /// Clears all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _notifyHistoryChanged();
  }

  /// Gets the current history size
  int get historySize => _undoStack.length;

  /// Gets the redo stack size
  int get redoStackSize => _redoStack.length;

  /// Notifies listeners of history changes
  void _notifyHistoryChanged() {
    _historyChangedController.add(null);
  }

  /// Disposes the service
  void dispose() {
    _historyChangedController.close();
  }
}
