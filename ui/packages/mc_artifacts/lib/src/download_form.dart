import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

class ArchiveDownloadForm extends StatefulWidget {
  const ArchiveDownloadForm({super.key});
  @override
  State<ArchiveDownloadForm> createState() => _ArchiveDownloadFormState();
}

class _ArchiveDownloadFormState extends State<ArchiveDownloadForm> {
  final form = GlobalKey<FormState>();
  final url = TextEditingController(),
      name = TextEditingController(),
      size = TextEditingController(),
      checksum = TextEditingController(),
      mirrors = TextEditingController();
  bool named = false;
  String? checkUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri == null ||
            !uri.hasAuthority ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.userInfo.isNotEmpty ||
            uri.fragment.isNotEmpty
        ? 'Enter an HTTP or HTTPS URL without credentials.'
        : null;
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(
      context,
      ArchiveDownloadRequest(
        name: name.text.trim(),
        sources: [
          url.text.trim(),
          ...mirrors.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty),
        ],
        expectedLength: size.text.trim().isEmpty
            ? null
            : int.parse(size.text.trim()),
        expectedSha256: checksum.text.trim().isEmpty
            ? null
            : checksum.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [url, name, size, checksum, mirrors]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => McFormDialog(
    title: 'Download archive',
    action: 'Download',
    onSubmit: submit,
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: url,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'URL'),
              validator: checkUrl,
              onChanged: (value) {
                if (named) return;
                try {
                  name.text =
                      Uri.tryParse(value)?.pathSegments.lastOrNull ?? '';
                } on FormatException {
                  name.clear();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => named = true,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a name.'
                  : value.length > 256
                  ? 'Use a shorter name.'
                  : null,
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Download options'),
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: size,
                  decoration: const InputDecoration(
                    labelText: 'Expected size in bytes (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null ||
                          value.trim().isEmpty ||
                          (int.tryParse(value.trim()) != null &&
                              int.parse(value.trim()) >= 0)
                      ? null
                      : 'Enter a whole number of bytes.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: checksum,
                  decoration: const InputDecoration(
                    labelText: 'Expected SHA-256 (optional)',
                  ),
                  validator: (value) =>
                      value == null ||
                          value.trim().isEmpty ||
                          RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value.trim())
                      ? null
                      : 'Enter all 64 hexadecimal characters.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: mirrors,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Other sources (one URL per line)',
                  ),
                  validator: (value) {
                    final sources = (value ?? '')
                        .split('\n')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty);
                    if (sources.length > 7)
                      return 'Use up to seven other sources.';
                    return sources.any((s) => checkUrl(s) != null)
                        ? 'Use one HTTP or HTTPS URL per line.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
