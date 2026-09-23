import 'command.dart';

/// Manages undo/redo history for commands
class CommandHistory {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  final int maxHistorySize;

  CommandHistory({this.maxHistorySize = 50});

  /// Execute a command and add it to history
  void execute(Command command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();

    // Limit history size
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo the last command
  void undo() {
    if (canUndo) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  /// Redo the last undone command
  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.execute();
      _undoStack.add(command);
    }
  }

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Get the description of the next undo command
  String? get undoDescription => canUndo ? _undoStack.last.description : null;

  /// Get the description of the next redo command
  String? get redoDescription => canRedo ? _redoStack.last.description : null;

  /// Clear all history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Get the current history size
  int get historySize => _undoStack.length;
}
