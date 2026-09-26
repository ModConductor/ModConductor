part of 'inspector.dart';

class _ManagedTextEditorInspector extends StatefulWidget {
  const _ManagedTextEditorInspector({
    required this.controller,
    required this.owner,
    required this.document,
    required this.onClose,
  });
  final FileInspectorController controller;
  final FilePlansController? owner;
  final ManagedTextDocument document;
  final VoidCallback onClose;

  @override
  State<_ManagedTextEditorInspector> createState() =>
      _ManagedTextEditorInspectorState();
}

class _ManagedTextEditorInspectorState
    extends State<_ManagedTextEditorInspector> {
  final _editor = GlobalKey<TextEditorToolboxState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.bindTextNavigationGuard(
          (navigate) => _editor.currentState!.guardNavigation(navigate),
        );
      }
    });
  }

  @override
  void didUpdateWidget(_ManagedTextEditorInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.bindTextNavigationGuard(null);
      widget.controller.bindTextNavigationGuard(
        (navigate) => _editor.currentState!.guardNavigation(navigate),
      );
    }
  }

  void closeEditor() {
    widget.controller.closeTextEditor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.editTextFocus.canRequestFocus) {
        widget.controller.editTextFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) => McInspector(
    title: 'Edit text',
    onClose: () => unawaited(_editor.currentState?.requestExit()),
    children: [
      TextEditorToolbox(
        key: _editor,
        document: widget.document.document,
        name: widget.document.source.target.last,
        source: widget.document.source.target.join('/'),
        saving: widget.controller.savingText,
        problem: widget.controller.textProblem,
        onClose: closeEditor,
        onExit: widget.onClose,
        onDiscard: widget.controller.abandonPendingText,
        onReadAgain: widget.owner == null
            ? null
            : () async {
                widget.controller.closeTextEditor();
                await widget.owner!.read();
              },
        onSave: (content) async {
          final saved = await widget.controller.saveText(content);
          if (saved) widget.owner?.invalidate();
          return saved;
        },
      ),
    ],
  );

  @override
  void dispose() {
    widget.controller.bindTextNavigationGuard(null);
    super.dispose();
  }
}
