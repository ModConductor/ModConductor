part of 'app.dart';

mixin _DesktopRequests on _AppStateBase {
  void _requestsChanged() {
    final requests = widget.desktopRequests;
    if (requests == null || !requests.isNexus || requests.id == null) return;
    if (identical(_dialogRequests, requests) &&
        _requestDialogRoute?.isCurrent == true) {
      _presentedRequestId = requests.id;
    }
    _scheduleIncomingRequest();
  }

  void _wakeModalSpaceWaiters() {
    for (final waiter in _modalSpaceWaiters) {
      waiter.complete();
    }
    _modalSpaceWaiters.clear();
  }

  void _requestRouteClosed() {
    _scheduleIncomingRequest();
    _wakeModalSpaceWaiters();
  }

  Future<void> _waitForArchiveForm() async {
    while (mounted) {
      _scheduleIncomingRequest();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final context = _requestShellKey.currentContext;
      if (context == null || !context.mounted) return;
      if (!_requestDialogOpen && ModalRoute.of(context)?.isCurrent == true) {
        return;
      }
      final waiter = Completer<void>();
      _modalSpaceWaiters.add(waiter);
      await waiter.future;
    }
  }

  void _scheduleIncomingRequest() {
    if (_requestPresentationScheduled || !mounted) return;
    _requestPresentationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPresentationScheduled = false;
      if (!mounted) return;
      final requests = widget.desktopRequests;
      final context = _requestShellKey.currentContext;
      if (requests == null ||
          !requests.isNexus ||
          requests.id == null ||
          requests.id == _presentedRequestId ||
          _requestDialogOpen ||
          context == null ||
          !context.mounted ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      unawaited(_presentRequests(context));
    });
  }

  Future<void> _presentRequests(BuildContext context) async {
    final requests = widget.desktopRequests;
    if (requests == null || _requestDialogOpen) return;
    _requestDialogOpen = true;
    _dialogRequests = requests;
    if (requests.isNexus) _presentedRequestId = requests.id;
    DesktopRequestChoice? choice;
    try {
      requests.selectContext(
        _workspaces.workspace?.id,
        _workspaces.workspace?.selectedProfile?.id,
      );
      choice = await showDialog<DesktopRequestChoice>(
        context: context,
        builder: (dialogContext) {
          _requestDialogRoute = ModalRoute.of(dialogContext);
          if (requests.isNexus && _requestDialogRoute?.isCurrent == true) {
            _presentedRequestId = requests.id;
          }
          return OpenRequestsDialog(
            requests: requests,
            workspaces: _workspaces,
            onRetry: widget.onRetry,
            onPreferences: () => _navigate(_Destination.preferences),
          );
        },
      );
    } finally {
      _requestDialogOpen = false;
      _dialogRequests = null;
      _requestDialogRoute = null;
      _requestRouteClosed();
    }
    if (choice != null && context.mounted) {
      await openDesktopRequest(
        context,
        choice,
        requests: requests,
        workspaces: _workspaces,
        artifacts: _artifacts,
        chooseFile: widget.chooseArchive,
        beforeArchiveForm: _waitForArchiveForm,
        onWorkspaceOpened: () => _navigate(
          _Destination.workspaces,
          focus: ModalRoute.of(context)?.isCurrent == true,
        ),
      );
    }
  }
}
