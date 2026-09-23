/// Base interface for undoable commands
abstract class Command {
  /// Execute the command
  void execute();

  /// Undo the command
  void undo();

  /// Get a description of the command for UI display
  String get description;
}
