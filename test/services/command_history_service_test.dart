import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/services/command_history_service.dart';
import 'package:ffmpeg_filter_app/models/command.dart';

// Test command implementation
class TestCommand extends Command {
  int value;
  final int increment;
  final String _description;

  TestCommand(this.value, this.increment, this._description);

  @override
  void execute() {
    value += increment;
  }

  @override
  void undo() {
    value -= increment;
  }

  @override
  String get description => _description;
}

void main() {
  group('CommandHistoryService', () {
    late CommandHistoryService service;

    setUp(() {
      service = CommandHistoryService(maxHistorySize: 10);
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with empty stacks', () {
      expect(service.canUndo, isFalse);
      expect(service.canRedo, isFalse);
      expect(service.historySize, equals(0));
      expect(service.redoStackSize, equals(0));
    });

    test('executeCommand executes and adds to undo stack', () {
      int value = 0;
      final command = TestCommand(value, 5, 'Add 5');

      service.executeCommand(command);

      expect(command.value, equals(5));
      expect(service.canUndo, isTrue);
      expect(service.canRedo, isFalse);
      expect(service.historySize, equals(1));
    });

    test('undo reverses the last command', () {
      int value = 0;
      final command = TestCommand(value, 5, 'Add 5');

      service.executeCommand(command);
      expect(command.value, equals(5));

      final undone = service.undo();

      expect(undone, isTrue);
      expect(command.value, equals(0));
      expect(service.canUndo, isFalse);
      expect(service.canRedo, isTrue);
    });

    test('redo reapplies undone command', () {
      int value = 0;
      final command = TestCommand(value, 5, 'Add 5');

      service.executeCommand(command);
      service.undo();
      expect(command.value, equals(0));

      final redone = service.redo();

      expect(redone, isTrue);
      expect(command.value, equals(5));
      expect(service.canUndo, isTrue);
      expect(service.canRedo, isFalse);
    });

    test('multiple commands can be undone in order', () {
      int value = 0;
      final command1 = TestCommand(value, 5, 'Add 5');
      final command2 = TestCommand(value, 3, 'Add 3');

      service.executeCommand(command1);
      service.executeCommand(command2);

      expect(command1.value, equals(5));
      expect(command2.value, equals(3));

      service.undo();
      expect(command2.value, equals(0));
      expect(command1.value, equals(5));

      service.undo();
      expect(command1.value, equals(0));
      expect(service.canUndo, isFalse);
    });

    test('undo returns false when stack is empty', () {
      final result = service.undo();
      expect(result, isFalse);
    });

    test('redo returns false when stack is empty', () {
      final result = service.redo();
      expect(result, isFalse);
    });

    test('executing new command clears redo stack', () {
      int value = 0;
      final command1 = TestCommand(value, 5, 'Add 5');
      final command2 = TestCommand(value, 3, 'Add 3');

      service.executeCommand(command1);
      service.undo();
      expect(service.canRedo, isTrue);

      service.executeCommand(command2);
      expect(service.canRedo, isFalse);
    });

    test('respects max history size', () {
      for (int i = 0; i < 15; i++) {
        service.executeCommand(TestCommand(0, i, 'Command $i'));
      }

      expect(service.historySize, equals(10));
    });

    test('clear removes all history', () {
      service.executeCommand(TestCommand(0, 5, 'Add 5'));
      service.undo();

      service.clear();

      expect(service.canUndo, isFalse);
      expect(service.canRedo, isFalse);
      expect(service.historySize, equals(0));
    });

    test('nextUndoDescription returns correct description', () {
      final command = TestCommand(0, 5, 'Add 5');
      service.executeCommand(command);

      expect(service.nextUndoDescription, equals('Add 5'));
    });

    test('nextRedoDescription returns correct description', () {
      final command = TestCommand(0, 5, 'Add 5');
      service.executeCommand(command);
      service.undo();

      expect(service.nextRedoDescription, equals('Add 5'));
    });

    test('nextUndoDescription returns null when stack is empty', () {
      expect(service.nextUndoDescription, isNull);
    });

    test('nextRedoDescription returns null when stack is empty', () {
      expect(service.nextRedoDescription, isNull);
    });

    test('historyChanged stream emits on command execution', () async {
      expectLater(
        service.historyChanged,
        emits(anything),
      );

      service.executeCommand(TestCommand(0, 5, 'Add 5'));
    });

    test('historyChanged stream emits on undo', () async {
      service.executeCommand(TestCommand(0, 5, 'Add 5'));

      expectLater(
        service.historyChanged,
        emits(anything),
      );

      service.undo();
    });

    test('historyChanged stream emits on clear', () async {
      service.executeCommand(TestCommand(0, 5, 'Add 5'));

      expectLater(
        service.historyChanged,
        emits(anything),
      );

      service.clear();
    });
  });
}
