import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class _QuickRenameResult {
  _QuickRenameResult({required this.newNames});
  final List<String> newNames; // same order as input
}

class _QuickRenameDialog extends StatefulWidget {
  const _QuickRenameDialog({required this.names});
  final List<String> names; // current outputName values (with extensions)

  @override
  State<_QuickRenameDialog> createState() => _QuickRenameDialogState();
}

class _QuickRenameDialogState extends State<_QuickRenameDialog> {
  final _watchCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  bool _useRegex = false;
  bool _caseSensitive = false;

  void _applyStripPrefix() {
    setState(() {
      _useRegex = true;
      _caseSensitive = false;
      _watchCtrl.text = r'^\[[^\]]+\]\s*';
      _replaceCtrl.text = '';
    });
  }

  void _applyStripTrailing() {
    setState(() {
      _useRegex = true;
      _caseSensitive = false;
      _watchCtrl.text = r'(\s*\[[^\]]+\])+$';
      _replaceCtrl.text = '';
    });
  }

  void _applyStripBoth() {
    setState(() {
      _useRegex = true;
      _caseSensitive = false;
      _watchCtrl.text = r'^\[[^\]]+\]\s*|(\s*\[[^\]]+\])+$';
      _replaceCtrl.text = '';
    });
  }

  @override
  void dispose() {
    _watchCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  List<String> _computePreview() {
    return widget.names.map(_renameOne).toList(growable: false);
  }

  String _renameOne(String original) {
    final base = path.basenameWithoutExtension(original);
    final ext = path.extension(original); // keep for UI consistency

    final watch = _watchCtrl.text;
    final replace = _replaceCtrl.text;

    if (watch.isEmpty) return base + ext;

    String newBase;
    if (_useRegex) {
      RegExp re;
      try {
        re = RegExp(watch, caseSensitive: _caseSensitive);
      } catch (_) {
        // Invalid regex, keep name unchanged
        return base + ext;
      }
      newBase = base.replaceAll(re, replace);
    } else {
      if (_caseSensitive) {
        newBase = base.replaceAll(watch, replace);
      } else {
        final re = RegExp(RegExp.escape(watch), caseSensitive: false);
        newBase = base.replaceAll(re, replace);
      }
    }

    // Trim any extra whitespace that may result
    newBase = newBase.trim();

    return newBase + ext;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _computePreview();
    final changedCount = List.generate(preview.length, (i) => i)
        .where((i) => preview[i] != widget.names[i])
        .length;

    return AlertDialog(
      title: const Text('Quick Rename'),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _watchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Find',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _replaceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Replace with',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _useRegex,
                  onChanged: (v) => setState(() => _useRegex = v ?? false),
                ),
                const Text('Use Regular Expression'),
                const SizedBox(width: 16),
                Checkbox(
                  value: _caseSensitive,
                  onChanged: (v) => setState(() => _caseSensitive = v ?? false),
                ),
                const Text('Case sensitive'),
                const Spacer(),
                Text('Changed: $changedCount / ${widget.names.length}')
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _applyStripPrefix,
                    child: const Text('Strip prefix [group]'),
                  ),
                  OutlinedButton(
                    onPressed: _applyStripTrailing,
                    child: const Text('Strip trailing [tags]'),
                  ),
                  OutlinedButton(
                    onPressed: _applyStripBoth,
                    child: const Text('Keep title + episode'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  itemCount: widget.names.length,
                  itemBuilder: (context, index) {
                    final original = widget.names[index];
                    final renamed = preview[index];
                    final changed = original != renamed;
                    return ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Expanded(
                              child: Text(original,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 12),
                          Icon(Icons.arrow_forward,
                              size: 16, color: Theme.of(context).hintColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              renamed,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: changed
                                    ? Theme.of(context).colorScheme.secondary
                                    : null,
                                fontWeight: changed ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _QuickRenameResult(newNames: _computePreview()),
          ),
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

Future<List<String>?> showQuickRenameDialog({
  required BuildContext context,
  required List<String> names,
}) async {
  final res = await showDialog<_QuickRenameResult?>(
    context: context,
    builder: (ctx) => _QuickRenameDialog(names: names),
  );
  return res?.newNames;
}
