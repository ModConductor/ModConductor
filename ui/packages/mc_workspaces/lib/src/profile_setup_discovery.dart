part of 'profile_setup.dart';

extension _ProfileSetupDiscovery on _ProfileSetupSurfaceState {
  Future<void> findInstallations() async {
    final selectedGame = game;
    if (busy ||
        selectedGame == null ||
        source != GameInstallationSource.steam) {
      return;
    }
    final client = widget.discovery;
    if (client == null) {
      _change(() {
        searched = true;
        candidates = const [];
        selectedInstallation = null;
        proton = null;
        steamRoots = const [];
        manualSelection = false;
        problem = null;
      });
      return;
    }
    _change(() {
      searching = true;
      problem = null;
      searched = true;
      candidates = const [];
      selectedInstallation = null;
      proton = null;
      steamRoots = const [];
      manualSelection = false;
    });
    final search = client.search(selectedGame.forSource(source), const []);
    pendingSearch = search;
    try {
      final result = await search.result;
      if (!mounted ||
          !identical(pendingSearch, search) ||
          game != selectedGame) {
        return;
      }
      _change(() {
        candidates = result.candidates;
        steamRoots = result.roots.map((root) => root.path).toList();
        selectedInstallation = result.candidates.length == 1
            ? result.candidates.single.directory.canonicalPath
            : null;
        folder.text = selectedInstallation ?? '';
      });
    } on Exception {
      if (mounted && identical(pendingSearch, search)) {
        _change(() => problem = 'The Steam search did not finish. Try again.');
      }
    } finally {
      if (mounted && identical(pendingSearch, search)) {
        _change(() {
          pendingSearch = null;
          searching = false;
        });
      }
    }
  }

  Future<void> selectProton() async {
    final client = widget.protonContexts;
    final selectedGame = game;
    final installation = selectedInstallation;
    if (!Platform.isLinux ||
        busy ||
        client == null ||
        selectedGame == null ||
        installation == null) {
      return;
    }
    final selected = await showDialog<ProtonSelection>(
      context: context,
      builder: (_) => ProtonDialog(
        gameId: selectedGame.forSource(source),
        gameName: selectedGame.name,
        steamAppId: selectedGame.steamAppId,
        gamePath: installation,
        client: client,
        chooseDirectory: widget.chooseDirectory,
        roots: steamRoots,
        initial: proton,
      ),
    );
    if (mounted &&
        selected != null &&
        game == selectedGame &&
        selectedInstallation == installation) {
      _change(() => proton = selected);
    }
  }
}
