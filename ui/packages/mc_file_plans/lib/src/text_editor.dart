import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class TextEditorToolbox extends StatefulWidget {
  const TextEditorToolbox({
    super.key,
    required this.document,
    required this.name,
    required this.source,
    required this.onSave,
    required this.onClose,
    this.problem,
    this.saving = false,
    this.saveLabel = 'Save as new mod version',
    this.onReadAgain,
  });

  final TextDocument document;
  final String name, source, saveLabel;
  final String? problem;
  final bool saving;
  final Future<bool> Function(String) onSave;
  final VoidCallback onClose;
  final Future<void> Function()? onReadAgain;

  @override
  State<TextEditorToolbox> createState() => TextEditorToolboxState();
}

class TextEditorToolboxState extends State<TextEditorToolbox> {
  late final TextEditingController _controller;
  late String _saved;
  final FocusNode _editorFocus = FocusNode();

  bool get dirty => _controller.text != _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.document.content;
    _controller = TextEditingController(text: _saved)..addListener(_changed);
  }

  void _changed() => setState(() {});

  Future<bool> _confirmDiscard() async {
    if (!dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: 'Discard changes?',
        actions: [
          McAction(
            label: 'Keep editing',
            onPressed: () => Navigator.pop(context, false),
          ),
          McAction(
            label: 'Discard',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [Text('Changes to ${widget.name} have not been saved.')],
      ),
    );
    if (discard != true && mounted) _editorFocus.requestFocus();
    return discard == true;
  }

  Future<bool> requestClose() async {
    if (!await _confirmDiscard()) return false;
    widget.onClose();
    return true;
  }

  Future<void> _readAgain() async {
    if (!await _confirmDiscard()) return;
    await widget.onReadAgain?.call();
  }

  Future<void> _save() async {
    if (!dirty || widget.saving) return;
    final content = _controller.text;
    if (await widget.onSave(content) && mounted) {
      _saved = content;
      setState(() {});
    }
  }

  String get _encoding => switch (widget.document.encoding) {
    TextDocumentEncoding.utf8 => 'UTF-8',
    TextDocumentEncoding.utf8Bom => 'UTF-8 with BOM',
    TextDocumentEncoding.utf16Little => 'UTF-16 LE with BOM',
    TextDocumentEncoding.utf16Big => 'UTF-16 BE with BOM',
  };

  String get _newline => switch (widget.document.newline) {
    TextDocumentNewline.noLineBreaks => 'No line breaks',
    TextDocumentNewline.lf => 'LF',
    TextDocumentNewline.crlf => 'CRLF',
  };

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
      const SingleActivator(LogicalKeyboardKey.escape): requestClose,
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
        if (dirty) ...[
          const SizedBox(height: 8),
          const McStatus(title: 'Unsaved changes'),
        ],
        const SizedBox(height: 6),
        Text(widget.source, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          '$_encoding · $_newline · ${widget.document.finalTerminator ? 'Ends with a line break' : 'No final line break'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (widget.problem != null) ...[
          McStatus(title: widget.problem!, tone: McStatusTone.error),
          const SizedBox(height: 12),
          if (widget.onReadAgain != null) ...[
            McAction(label: 'Read again', onPressed: _readAgain),
            const SizedBox(height: 12),
          ],
        ],
        SizedBox(
          height: 320,
          child: TextField(
            key: const ValueKey('text-editor'),
            controller: _controller,
            focusNode: _editorFocus,
            expands: true,
            maxLines: null,
            minLines: null,
            enabled: !widget.saving,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            McAction(
              label: widget.problem == null ? 'Discard' : 'Discard draft',
              onPressed: widget.saving ? null : requestClose,
            ),
            McAction(
              label: widget.saveLabel,
              emphasis: McActionEmphasis.primary,
              onPressed: dirty && !widget.saving ? _save : null,
            ),
          ],
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    _editorFocus.dispose();
    super.dispose();
  }
}
