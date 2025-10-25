/// Abstract base class for the Command pattern
/// Enables undo/redo functionality for reversible operations
abstract class Command {
  /// Executes the command
  void execute();

  /// Undoes the command
  void undo();

  /// Optional description of what the command does
  String get description;
}
