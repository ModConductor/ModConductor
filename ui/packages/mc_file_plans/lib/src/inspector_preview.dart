part of 'inspector.dart';

String fileSize(int bytes) => bytes >= 1024 * 1024 * 1024
    ? '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB'
    : bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB'
    : bytes >= 1024
    ? '${(bytes / 1024).toStringAsFixed(1)} KiB'
    : '$bytes B';

List<Widget> _filePreviewChildren(
  FileInspectorController view,
  bool available,
) => [
  const SizedBox(height: 16),
  SegmentedButton<FilePreviewRepresentation>(
    segments: const [
      ButtonSegment(value: FilePreviewRepresentation.text, label: Text('Text')),
      ButtonSegment(
        value: FilePreviewRepresentation.image,
        label: Text('Image'),
      ),
      ButtonSegment(value: FilePreviewRepresentation.hex, label: Text('Hex')),
    ],
    selected: {view.previewRepresentation},
    onSelectionChanged: (values) =>
        view.setPreviewRepresentation(values.single),
  ),
  const SizedBox(height: 12),
  if (view.previewLoading) ...[
    const LinearProgressIndicator(),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: view.cancelPreview,
        child: const Text('Cancel preview'),
      ),
    ),
  ] else if (view.previewProblem != null) ...[
    McStatus(title: view.previewProblem!, tone: McStatusTone.error),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => unawaited(view.loadPreview()),
        child: const Text('Retry preview'),
      ),
    ),
  ] else if (view.preview != null)
    _PreviewBody(preview: view.preview!),
  if (view.canEditText) ...[
    const SizedBox(height: 12),
    McAction(
      label: 'Edit text',
      icon: Icons.edit_outlined,
      focusNode: view.editTextFocus,
      onPressed: available && !view.openingText
          ? () => unawaited(view.openTextEditor())
          : null,
    ),
  ],
  if (view.openingText) ...[
    const SizedBox(height: 12),
    const LinearProgressIndicator(),
  ],
  if (view.textProblem != null) ...[
    const SizedBox(height: 12),
    McStatus(title: view.textProblem!, tone: McStatusTone.error),
  ],
];

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.preview});
  final FilePreviewResult preview;

  @override
  Widget build(BuildContext context) {
    if (preview.status != FilePreviewStatus.ready) {
      return McStatus(
        title: preview.detail ?? 'This source cannot be previewed.',
        tone: preview.status == FilePreviewStatus.changed
            ? McStatusTone.error
            : McStatusTone.neutral,
      );
    }
    return switch (preview.content) {
      FilePreviewText value => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                value.content,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ),
      FilePreviewImage value => FilePreviewImageView(preview: value),
      FilePreviewHex value => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.truncated)
            Text(
              'Showing the first ${fileSize(value.content.length)} of ${fileSize(value.totalLength)}.',
            ),
          if (value.truncated) const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: SingleChildScrollView(
              child: SelectableText(
                _hex(value.content),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
      null => const McStatus(title: 'This source has no preview.'),
    };
  }

  static String _hex(List<int> bytes) {
    final output = StringBuffer();
    for (var offset = 0; offset < bytes.length; offset += 16) {
      output.write(offset.toRadixString(16).padLeft(8, '0'));
      output.write('  ');
      final end = (offset + 16).clamp(0, bytes.length);
      for (var index = offset; index < end; ++index) {
        output.write(bytes[index].toRadixString(16).padLeft(2, '0'));
        output.write(index == offset + 7 ? '  ' : ' ');
      }
      output.writeln();
    }
    return output.toString();
  }
}
