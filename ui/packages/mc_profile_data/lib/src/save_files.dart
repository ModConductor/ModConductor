import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mc_client/mc_client.dart';
import 'package:mc_ui_collections/mc_ui_collections.dart';
import 'package:mc_ui_foundation/mc_ui_foundation.dart';

part 'save_files_session.dart';
part 'save_files_view.dart';

class ProfileSaveFiles extends StatefulWidget {
  const ProfileSaveFiles({
    super.key,
    required this.client,
    required this.workspace,
    required this.profile,
    required this.expected,
    required this.onChanged,
    this.headersId,
  });
  final ProfileDataClient client;
  final String workspace;
  final ProfileInfo profile;
  final ProfileDataRef expected;
  final String? headersId;
  final VoidCallback onChanged;
  @override
  State<ProfileSaveFiles> createState() => _ProfileSaveFilesState();
}

class _ProfileSaveFilesState extends State<ProfileSaveFiles> {
  late final _session = _SaveFilesSession(widget);

  @override
  void initState() {
    super.initState();
    _session.addListener(_changed);
  }

  @override
  void didUpdateWidget(ProfileSaveFiles oldWidget) {
    super.didUpdateWidget(oldWidget);
    _session.config = widget;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_changed);
    _session.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final copy = _session.source == ProfileSaveSource.global;
    final value = await _session.preview();
    if (!mounted || value == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => McDialog(
        title: copy
            ? 'Copy save to ${widget.profile.name}?'
            : 'Permanently delete save?',
        actions: [
          McAction(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          McAction(
            label: copy ? 'Copy to profile' : 'Delete permanently',
            emphasis: McActionEmphasis.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          _SaveFact('Source', _displaySavePath(value.source)),
          if (value.destination case final destination?)
            _SaveFact('Destination', _displaySavePath(destination)),
          _SaveFact('Files', value.files.map((file) => file.name).join('\n')),
          if (!copy) ...[
            const McStatus(
              title: 'This deletion is permanent.',
              detail: 'Global saves will not be changed.',
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'If a selected file changes before this action starts, nothing will be changed.',
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _session.apply(value);
  }

  void _closeDetails() {
    _session.inspection = null;
    _session.model.clearSelection();
  }

  Widget _content(BoxConstraints constraints) {
    if (constraints.maxWidth < 760) {
      return _session.inspection == null && _session.model.selected == null
          ? _SaveGroupCollection(session: _session, onPreview: _preview)
          : _SaveDetails(
              session: _session,
              onClose: _closeDetails,
              onPreview: _preview,
              actionInFooter: true,
            );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _SaveGroupCollection(session: _session, onPreview: _preview),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: _SaveDetails(
            session: _session,
            onClose: _closeDetails,
            onPreview: _preview,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_session.busy,
    child: McDialog(
      title: '${widget.profile.name} saves',
      contentWidth: 1040,
      actions: [
        McAction(
          label: 'Close',
          onPressed: _session.busy ? null : () => Navigator.pop(context),
        ),
      ],
      children: [
        if (_session.path case final value?) ...[
          Text(
            _displaySavePath(value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 590,
          child: LayoutBuilder(builder: (context, bounds) => _content(bounds)),
        ),
      ],
    ),
  );
}
