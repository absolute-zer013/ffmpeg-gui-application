import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rename_service.dart';
import '../utils/rename_utils.dart';
import '../models/rename_pattern.dart';

class BatchRenameDialog extends StatefulWidget {
  final List<String> paths;

  const BatchRenameDialog({super.key, required this.paths});

  @override
  State<BatchRenameDialog> createState() => _BatchRenameDialogState();
}

class _BatchRenameDialogState extends State<BatchRenameDialog> {
  final _patternCtrl =
      TextEditingController(text: '{name} - S{season:2}E{episode:2}');
  final _startIndexCtrl = TextEditingController(text: '1');
  final _episodeStartCtrl = TextEditingController(text: '1');
  final _seasonCtrl = TextEditingController(text: '1');
  final _yearCtrl = TextEditingController();
  String _conflictStrategy = RenameUtils.conflictSuffix;
  List<RenamePattern> _presets = const [];
  RenamePattern? _selectedPreset;

  BatchRenamePlan? _plan;
  String? _patternError;
  List<String> _variableHints = const [];
  List<String> _warnings = const [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadPrefs().then((_) => _recompute());
  }

  void _loadPresets() {
    _presets = RenamePattern.getPredefinedPatterns();
    // Pick a default if pattern matches a preset
    _selectedPreset = _presets.firstWhere(
      (p) => p.pattern == _patternCtrl.text,
      orElse: () => _presets.first,
    );
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final pattern = prefs.getString('batchRename.pattern');
    final startIndex = prefs.getInt('batchRename.startIndex');
    final episodeStart = prefs.getInt('batchRename.episodeStart');
    final season = prefs.getInt('batchRename.season');
    final year = prefs.getInt('batchRename.year');
    final strategy = prefs.getString('batchRename.conflictStrategy');

    if (pattern != null && pattern.isNotEmpty) {
      _patternCtrl.text = pattern;
    }
    if (startIndex != null) _startIndexCtrl.text = startIndex.toString();
    if (episodeStart != null) {
      _episodeStartCtrl.text = episodeStart.toString();
    }
    if (season != null) _seasonCtrl.text = season.toString();
    if (year != null) _yearCtrl.text = year.toString();
    if (strategy != null) _conflictStrategy = strategy;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('batchRename.pattern', _patternCtrl.text);
    await prefs.setInt('batchRename.startIndex',
        int.tryParse(_startIndexCtrl.text.trim()) ?? 1);
    final ep = int.tryParse(_episodeStartCtrl.text.trim());
    if (ep != null) await prefs.setInt('batchRename.episodeStart', ep);
    final s = int.tryParse(_seasonCtrl.text.trim());
    if (s != null) await prefs.setInt('batchRename.season', s);
    final y = int.tryParse(_yearCtrl.text.trim());
    if (y != null) await prefs.setInt('batchRename.year', y);
    await prefs.setString('batchRename.conflictStrategy', _conflictStrategy);
  }

  void _recompute() {
    final pattern = _patternCtrl.text;
    final err = RenameUtils.validatePattern(pattern);
    setState(() => _patternError = err);
    if (err != null) {
      setState(() => _plan = null);
      return;
    }

    int parse(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
    final startIndex = parse(_startIndexCtrl);
    final episodeStart = parse(_episodeStartCtrl);
    final season = parse(_seasonCtrl);
    final year = _yearCtrl.text.trim().isNotEmpty
        ? int.tryParse(_yearCtrl.text.trim())
        : null;

    // Variables + warnings
    final vars = RenameUtils.extractVariables(pattern);
    _variableHints = vars;
    final warnings = <String>[];
    if (vars.contains('episode') && (episodeStart <= 0)) {
      warnings.add('Pattern uses {episode} but Episode Start is empty');
    }
    if (vars.contains('season') && (season <= 0)) {
      warnings.add('Pattern uses {season} but Season is empty');
    }
    if (vars.contains('index') && (startIndex <= 0)) {
      warnings.add('Pattern uses {index} but Start Index is empty');
    }
    if (vars.contains('year') && year == null) {
      warnings.add('Pattern uses {year} but Year is empty');
    }
    _warnings = warnings;

    final plan = RenameService.planBatchRenames(
      pattern: pattern,
      paths: widget.paths,
      startIndex: startIndex > 0 ? startIndex : 1,
      episodeStart: episodeStart > 0 ? episodeStart : null,
      season: season > 0 ? season : null,
      year: year,
      conflictStrategy: _conflictStrategy,
    );
    setState(() => _plan = plan);
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Rename Preview'),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<RenamePattern>(
                    initialValue: _presets.contains(_selectedPreset)
                        ? _selectedPreset
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Preset',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: _presets
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedPreset = v);
                      _patternCtrl.text = v.pattern;
                      _recompute();
                    },
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: _patternCtrl,
                    decoration: InputDecoration(
                      labelText: 'Pattern',
                      hintText: '{name} - S{season:2}E{episode:2}',
                      errorText: _patternError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _recompute(),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _startIndexCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Index',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recompute(),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _episodeStartCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Episode Start',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recompute(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _seasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recompute(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _recompute(),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: _conflictStrategy,
                    decoration: const InputDecoration(
                      labelText: 'On Conflict',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: RenameUtils.conflictSuffix,
                          child: Text('Add numeric suffix')),
                      DropdownMenuItem(
                          value: RenameUtils.conflictSkip,
                          child: Text('Skip item')),
                      DropdownMenuItem(
                          value: RenameUtils.conflictError,
                          child: Text('Mark as error')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _conflictStrategy = v);
                        _recompute();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Variable hints and warnings
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_variableHints.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Variables:', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 6,
                        children: _variableHints
                            .map((v) => Chip(
                                  label: Text('{$v}',
                                      style: const TextStyle(fontSize: 11)),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ..._warnings.map((w) => Chip(
                      label: Text(w, style: const TextStyle(fontSize: 11)),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            if (_plan != null)
              Text(
                'Resolved: ${_plan!.resolvedConflicts} • Skipped: ${_plan!.skippedItems}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 8),
            // Preview table
            Expanded(
              child: _plan == null
                  ? const Center(
                      child: Text('Enter a valid pattern to preview'))
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: _plan!.results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _plan!.results[i];
                          final base = p.basename(r.originalPath);
                          return ListTile(
                            dense: true,
                            leading: r.skipped
                                ? const Icon(Icons.block, color: Colors.orange)
                                : r.conflictResolved
                                    ? const Icon(Icons.auto_fix_high,
                                        color: Colors.blue)
                                    : const Icon(Icons.check,
                                        color: Colors.green),
                            title: Text(base, overflow: TextOverflow.ellipsis),
                            subtitle: r.reason != null
                                ? Text(r.reason!,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: SizedBox(
                              width: 260,
                              child: Text(
                                r.proposedName,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
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
        OutlinedButton.icon(
          onPressed: _plan == null ? null : _exportCsv,
          icon: const Icon(Icons.table_chart),
          label: const Text('Export CSV'),
        ),
        OutlinedButton.icon(
          onPressed: _plan == null ? null : _exportMarkdown,
          icon: const Icon(Icons.description),
          label: const Text('Export MD'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _plan != null && _patternError == null
              ? () {
                  Navigator.pop(
                      context,
                      BatchRenameDialogResult(
                        pattern: _patternCtrl.text,
                        plan: _plan!,
                        startIndex:
                            int.tryParse(_startIndexCtrl.text.trim()) ?? 1,
                        episodeStart:
                            int.tryParse(_episodeStartCtrl.text.trim()),
                        season: int.tryParse(_seasonCtrl.text.trim()),
                        year: int.tryParse(_yearCtrl.text.trim()),
                      ));
                }
              : null,
          child: const Text('Apply to Files'),
        ),
      ],
    );
  }

  Future<void> _exportCsv() async {
    if (_plan == null) return;
    final rows = <List<String>>[
      ['Original', 'Proposed', 'Status', 'Reason'],
      ..._plan!.results.map((r) => [
            p.basename(r.originalPath),
            r.proposedName,
            r.skipped ? 'Skipped' : (r.conflictResolved ? 'Resolved' : 'OK'),
            r.reason ?? '',
          ]),
    ];
    final csv = rows.map((r) => r.map(_csvEscape).join(',')).join('\n');

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Batch Rename Preview (CSV)',
      fileName: 'batch-rename-preview.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;
    await File(savePath).writeAsString(csv);
  }

  String _csvEscape(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    var out = v.replaceAll('"', '""');
    return needsQuotes ? '"$out"' : out;
  }

  Future<void> _exportMarkdown() async {
    if (_plan == null) return;
    final buffer = StringBuffer();
    buffer.writeln('| Original | Proposed | Status | Reason |');
    buffer.writeln('|---|---|---|---|');
    for (final r in _plan!.results) {
      final status =
          r.skipped ? 'Skipped' : (r.conflictResolved ? 'Resolved' : 'OK');
      buffer.writeln(
          '| ${_mdEscape(p.basename(r.originalPath))} | ${_mdEscape(r.proposedName)} | $status | ${_mdEscape(r.reason ?? '')} |');
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Batch Rename Preview (Markdown)',
      fileName: 'batch-rename-preview.md',
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown'],
    );
    if (savePath == null) return;
    await File(savePath).writeAsString(buffer.toString());
  }

  String _mdEscape(String v) => v.replaceAll('|', '\\|');
}

class BatchRenameDialogResult {
  final String pattern;
  final BatchRenamePlan plan;
  final int startIndex;
  final int? episodeStart;
  final int? season;
  final int? year;

  BatchRenameDialogResult({
    required this.pattern,
    required this.plan,
    required this.startIndex,
    this.episodeStart,
    this.season,
    this.year,
  });
}

/// Helper to show dialog and get a strongly typed result in calling code.
Future<BatchRenameDialogResult?> showBatchRenameDialog({
  required BuildContext context,
  required List<String> paths,
}) {
  return showDialog<BatchRenameDialogResult?>(
    context: context,
    builder: (_) => BatchRenameDialog(paths: paths),
  );
}
