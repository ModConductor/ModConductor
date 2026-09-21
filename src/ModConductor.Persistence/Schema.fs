namespace ModConductor.Persistence

module internal Schema =
    [<Literal>]
    let CurrentVersion = 1L

    [<Literal>]
    let ApplicationId = 1296253774L

    let sql =
        """
CREATE TABLE archive_installations(
          id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),artifact_id TEXT NOT NULL,
          owner TEXT NOT NULL,state INTEGER NOT NULL,busy INTEGER NOT NULL,cancelled INTEGER NOT NULL DEFAULT 0,
          fingerprint TEXT NOT NULL,archive_name TEXT NOT NULL,name TEXT NOT NULL,version_label TEXT NOT NULL,
          source_digest TEXT NOT NULL,source_revision INTEGER NOT NULL,root TEXT NOT NULL,
          mod_id TEXT NOT NULL,version_id TEXT NOT NULL,total_bytes INTEGER NOT NULL,total_files INTEGER NOT NULL,problem TEXT, target_revision INTEGER, previous_version TEXT);
CREATE TABLE archive_version_origins(
          version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),artifact_id TEXT NOT NULL REFERENCES artifacts(id));
CREATE TABLE artifact_downloads(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      sources TEXT NOT NULL,expected_length INTEGER,expected_sha TEXT,
      state INTEGER NOT NULL,bytes INTEGER NOT NULL,total INTEGER,etag TEXT,effective_url TEXT,
      source_index INTEGER NOT NULL,attempt INTEGER NOT NULL,retry_at INTEGER,
      restart_required INTEGER NOT NULL,checksum_matched INTEGER NOT NULL, nexus_version TEXT);
CREATE TABLE artifact_links(
      artifact_id TEXT NOT NULL REFERENCES artifacts(id),mod_id TEXT NOT NULL REFERENCES mods(id),
      version_id TEXT NOT NULL REFERENCES mod_versions(id),mod_name TEXT NOT NULL,version_label TEXT NOT NULL, installed INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(artifact_id,mod_id,version_id));
CREATE TABLE artifacts(
      id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),revision INTEGER NOT NULL,
      original_name TEXT NOT NULL,original_path TEXT NOT NULL,path TEXT NOT NULL,storage INTEGER NOT NULL,
      phase INTEGER NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,
      length INTEGER,sha256 TEXT,source_identity TEXT,stored_identity TEXT,problem TEXT);
CREATE TABLE bundle_mods(id TEXT PRIMARY KEY,bundle_id TEXT NOT NULL REFERENCES bundle_work(id),source_id TEXT NOT NULL UNIQUE REFERENCES bundle_sources(id),mod_id TEXT NOT NULL UNIQUE,name TEXT NOT NULL,position INTEGER NOT NULL,attempt TEXT REFERENCES archive_installations(id));
CREATE TABLE bundle_sources(id TEXT PRIMARY KEY,bundle_id TEXT NOT NULL REFERENCES bundle_work(id),parent_id TEXT REFERENCES bundle_sources(id),entry_index INTEGER NOT NULL,path TEXT NOT NULL,expected_length INTEGER NOT NULL,identity TEXT,length INTEGER,digest TEXT,leaf_entries INTEGER NOT NULL DEFAULT 0,leaf_bytes INTEGER NOT NULL DEFAULT 0,problem TEXT,UNIQUE(bundle_id,parent_id,entry_index));
CREATE TABLE bundle_version_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),parent_digest TEXT NOT NULL,path_chain TEXT NOT NULL,digest_chain TEXT NOT NULL);
CREATE TABLE bundle_work(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL UNIQUE REFERENCES workspaces(id),artifact_id TEXT NOT NULL REFERENCES artifacts(id),archive_name TEXT NOT NULL,parent_digest TEXT NOT NULL,revision INTEGER NOT NULL DEFAULT 0,owner TEXT NOT NULL,busy INTEGER NOT NULL DEFAULT 0,problem TEXT);
CREATE TABLE categories(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), parent_id TEXT REFERENCES categories(id), label TEXT NOT NULL, missing INTEGER NOT NULL DEFAULT 0);
CREATE TABLE deployment_contexts(id TEXT PRIMARY KEY, revision INTEGER NOT NULL, pending TEXT, body BLOB NOT NULL, digest TEXT NOT NULL);
CREATE TABLE deployment_generations(context_id TEXT NOT NULL REFERENCES deployment_contexts(id), id TEXT NOT NULL, body BLOB NOT NULL, digest TEXT NOT NULL, unavailable TEXT, PRIMARY KEY(context_id,id));
CREATE TABLE deployment_receipts(sequence INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE, context_id TEXT NOT NULL REFERENCES deployment_contexts(id), previous_id TEXT, proposed_id TEXT NOT NULL, revision INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 0 AND 4), owner TEXT NOT NULL, busy INTEGER NOT NULL, abandoned INTEGER NOT NULL, body BLOB NOT NULL, digest TEXT NOT NULL, FOREIGN KEY(context_id,previous_id) REFERENCES deployment_generations(context_id,id), FOREIGN KEY(context_id,proposed_id) REFERENCES deployment_generations(context_id,id));
CREATE TABLE enb_configuration_operations(
      receipt_id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
      generation_id TEXT,
      kind TEXT NOT NULL,
      phase TEXT NOT NULL,
      values_text TEXT NOT NULL,
      action_id TEXT,
      detail TEXT NOT NULL
    );
CREATE TABLE enb_generation_components(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      component_version TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER,
      nexus_file INTEGER,
      source_url TEXT NOT NULL,
      terms_url TEXT NOT NULL,
      checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id,kind)
    );
CREATE TABLE enb_launch_plans(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      preset_version TEXT NOT NULL,
      runtime_sha256 TEXT NOT NULL,
      preset_sha256 TEXT NOT NULL,
      companion_provenance TEXT NOT NULL,
      dll_overrides TEXT NOT NULL,
      selected_runtime TEXT NOT NULL,
      previous_values TEXT NOT NULL,
      configuration_action TEXT,
      PRIMARY KEY(profile_id,generation_id)
    );
CREATE TABLE enb_pending_sources(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      runtime_artifact_id TEXT NOT NULL REFERENCES artifacts(id),
      runtime_sha256 TEXT NOT NULL,
      kind TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_bytes INTEGER,
      account_id TEXT NOT NULL,
      checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,kind)
    );
CREATE TABLE enb_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      preset_version TEXT NOT NULL,
      artifact_id TEXT,
      archive_sha256 TEXT,
      checked_at TEXT NOT NULL
    );
CREATE TABLE enb_selection_intents(
      receipt_id TEXT NOT NULL,
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      expected_revision INTEGER NOT NULL,
      mod_id TEXT NOT NULL,
      enabled INTEGER NOT NULL,
      PRIMARY KEY(receipt_id,mod_id)
    );
CREATE TABLE executable_presets(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),revision INTEGER NOT NULL,data TEXT NOT NULL);
CREATE TABLE executable_runs(sequence INTEGER PRIMARY KEY,id TEXT NOT NULL UNIQUE,workspace_id TEXT NOT NULL REFERENCES workspaces(id),preset_id TEXT NOT NULL,owner TEXT NOT NULL,revision INTEGER NOT NULL,phase INTEGER NOT NULL,data TEXT NOT NULL);
CREATE TABLE file_visibility_changes(id INTEGER PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL,version_id TEXT NOT NULL,path TEXT NOT NULL,hidden INTEGER NOT NULL,before_hidden INTEGER NOT NULL,profile_id TEXT NOT NULL,before_fingerprint TEXT NOT NULL,after_fingerprint TEXT NOT NULL,recorded_at TEXT NOT NULL);
CREATE TABLE file_visibility_state(workspace_id TEXT PRIMARY KEY REFERENCES workspaces(id),revision INTEGER NOT NULL);
CREATE TABLE fnis_artifact_selections(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      checked_at TEXT NOT NULL
    );
CREATE TABLE fnis_generators(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      artifact_id TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      provider TEXT NOT NULL,
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      acquired_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id)
    );
CREATE TABLE fnis_outputs(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      mod_id TEXT NOT NULL REFERENCES mods(id),
      version_id TEXT NOT NULL REFERENCES mod_versions(id),
      run_id TEXT NOT NULL REFERENCES fnis_runs(id),
      input_fingerprint TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
CREATE TABLE fnis_pending_handoffs(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      checked_at TEXT NOT NULL
    );
CREATE TABLE fnis_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      component_version TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      nexus_file INTEGER,
      artifact_id TEXT,
      checked_at TEXT NOT NULL
    );
CREATE TABLE fnis_publication_intents(
      receipt_id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      kind INTEGER NOT NULL CHECK(kind IN (0,1)),
      expected_selection_revision INTEGER NOT NULL,
      previous_mod_id TEXT,
      mod_id TEXT,
      version_id TEXT,
      artifact_id TEXT,
      file_name TEXT,
      file_version TEXT,
      generation_id TEXT NOT NULL,
      executable TEXT,
      component_version TEXT,
      archive_sha256 TEXT,
      provider TEXT,
      source TEXT,
      terms TEXT,
      nexus_mod INTEGER,
      nexus_file INTEGER,
      acquired_at TEXT
    );
CREATE TABLE fnis_runs(
      id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      owner TEXT NOT NULL,
      busy INTEGER NOT NULL CHECK(busy IN(0,1)),
      phase INTEGER NOT NULL CHECK(phase BETWEEN 0 AND 7),
      generation_id TEXT NOT NULL,
      generator TEXT NOT NULL,
      input_fingerprint TEXT NOT NULL,
      expected_selection_revision INTEGER,
      output_mod_id TEXT NOT NULL,
      output_version_id TEXT NOT NULL,
      exit_code INTEGER,
      stdout BLOB NOT NULL,
      stderr BLOB NOT NULL,
      problem TEXT,
      requested_at TEXT NOT NULL,
      completed_at TEXT
    , run_log BLOB NOT NULL DEFAULT X'');
CREATE TABLE game_contexts(
                    profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
                    workspace_id TEXT NOT NULL REFERENCES workspaces(id),
                    game_id TEXT NOT NULL,
                    id TEXT NOT NULL,
                    path TEXT NOT NULL,
                    revision INTEGER NOT NULL,
                    evidence TEXT NOT NULL,
                    checked_owner TEXT NOT NULL,
                    failure TEXT,
                    proton_selection TEXT
                );
CREATE TABLE hidden_mod_files(workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL REFERENCES mods(id),version_id TEXT NOT NULL REFERENCES mod_versions(id),path TEXT NOT NULL,hidden INTEGER NOT NULL CHECK(hidden IN (0,1)),PRIMARY KEY(workspace_id,mod_id,version_id,path));
CREATE TABLE installation_destinations(
          installation_id TEXT NOT NULL,entry_index INTEGER NOT NULL,path TEXT NOT NULL,
          PRIMARY KEY(installation_id,path),
          FOREIGN KEY(installation_id,entry_index) REFERENCES installation_files(installation_id,entry_index) ON DELETE CASCADE);
CREATE TABLE installation_files(
          installation_id TEXT NOT NULL REFERENCES archive_installations(id),entry_index INTEGER NOT NULL,
          destination TEXT NOT NULL,payload_id TEXT NOT NULL UNIQUE,identity TEXT,length INTEGER,digest TEXT, reused_payload TEXT,
          PRIMARY KEY(installation_id,entry_index));
CREATE TABLE installation_reuse(installation_id TEXT NOT NULL REFERENCES archive_installations(id),path TEXT NOT NULL,payload_id TEXT NOT NULL REFERENCES mod_payloads(id),PRIMARY KEY(installation_id,path));
CREATE TABLE mod_categories(mod_id TEXT NOT NULL REFERENCES mods(id), category_id TEXT NOT NULL, label TEXT NOT NULL, PRIMARY KEY(mod_id,category_id));
CREATE TABLE mod_deletion_artifacts(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),artifact_id TEXT NOT NULL UNIQUE,PRIMARY KEY(deletion_id,artifact_id));
CREATE TABLE mod_deletion_effects(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),sequence INTEGER NOT NULL,kind INTEGER NOT NULL,root TEXT NOT NULL,root_identity TEXT NOT NULL,path TEXT NOT NULL,identity TEXT,label TEXT NOT NULL,bytes INTEGER,PRIMARY KEY(deletion_id,sequence));
CREATE TABLE mod_deletion_targets(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),mod_id TEXT NOT NULL UNIQUE,PRIMARY KEY(deletion_id,mod_id));
CREATE TABLE mod_deletions(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL UNIQUE,name TEXT NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,problem TEXT);
CREATE TABLE mod_edit_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),edit_id TEXT NOT NULL UNIQUE,source_version TEXT NOT NULL REFERENCES mod_versions(id),path TEXT NOT NULL,previous_payload TEXT NOT NULL REFERENCES mod_payloads(id),content BLOB NOT NULL,digest TEXT NOT NULL);
CREATE TABLE mod_libraries(workspace_id TEXT PRIMARY KEY REFERENCES workspaces(id), directory TEXT NOT NULL UNIQUE, owner TEXT NOT NULL, phase INTEGER NOT NULL, identity TEXT);
CREATE TABLE mod_manifest(version_id TEXT NOT NULL REFERENCES mod_versions(id), path TEXT NOT NULL, payload_id TEXT NOT NULL REFERENCES mod_payloads(id), PRIMARY KEY(version_id,path));
CREATE TABLE mod_nexus_files(mod_id TEXT NOT NULL REFERENCES mod_nexus_links(mod_id) ON DELETE CASCADE,file_id INTEGER NOT NULL,name TEXT NOT NULL,version TEXT NOT NULL,category TEXT NOT NULL,description TEXT NOT NULL,bytes INTEGER,category_id INTEGER NOT NULL,uploaded INTEGER,PRIMARY KEY(mod_id,file_id));
CREATE TABLE mod_nexus_links(mod_id TEXT PRIMARY KEY REFERENCES mods(id) ON DELETE CASCADE,revision INTEGER NOT NULL DEFAULT 0,game TEXT,nexus_mod INTEGER,name TEXT,summary TEXT,version TEXT,author TEXT,uploader TEXT,category_id INTEGER,category_label TEXT,modified INTEGER,available INTEGER,allows_rating INTEGER,checked INTEGER,checked_owner TEXT,problem TEXT,mapped_provider INTEGER,mapped_category TEXT);
CREATE TABLE mod_nexus_updates(mod_id TEXT NOT NULL REFERENCES mod_nexus_links(mod_id) ON DELETE CASCADE,previous INTEGER NOT NULL,next INTEGER NOT NULL,PRIMARY KEY(mod_id,previous,next));
CREATE TABLE mod_payloads(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), publication_id TEXT NOT NULL REFERENCES mod_versions(id), identity TEXT, length INTEGER, digest TEXT);
CREATE TABLE mod_version_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),output_action TEXT NOT NULL,source_version TEXT,version_label TEXT NOT NULL);
CREATE TABLE mod_versions(id TEXT PRIMARY KEY, mod_id TEXT NOT NULL REFERENCES mods(id), expected_revision INTEGER NOT NULL, owner TEXT NOT NULL, phase INTEGER NOT NULL, busy INTEGER NOT NULL, cancelled INTEGER NOT NULL DEFAULT 0);
CREATE TABLE mods(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), kind INTEGER NOT NULL, name TEXT NOT NULL, notes TEXT NOT NULL, comment TEXT NOT NULL, version_text TEXT NOT NULL, source_text TEXT NOT NULL, revision INTEGER NOT NULL, source_path TEXT, source_identity TEXT, current_version TEXT REFERENCES mod_versions(id), status INTEGER NOT NULL);
CREATE TABLE operation_events ( cursor INTEGER PRIMARY KEY, id TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL, progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL);
CREATE TABLE operation_state (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL, cursor INTEGER NOT NULL);
INSERT INTO operation_state VALUES(1,0,0);
CREATE TABLE operations ( id TEXT PRIMARY KEY, owner TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 1 AND 5), progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL, last_cursor INTEGER NOT NULL, migration_staged_path TEXT, migration_final_path TEXT);
CREATE TABLE output_actions(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL,context_id TEXT NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,complete INTEGER NOT NULL,version_id TEXT,body BLOB NOT NULL,FOREIGN KEY(workspace_id,context_id) REFERENCES output_contexts(workspace_id,id));
CREATE TABLE output_contexts(workspace_id TEXT NOT NULL REFERENCES workspaces(id),id TEXT NOT NULL,game_path TEXT NOT NULL,revision INTEGER NOT NULL,PRIMARY KEY(workspace_id,id));
CREATE TABLE output_locations(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL,context_id TEXT NOT NULL,name TEXT NOT NULL,purpose INTEGER NOT NULL CHECK(purpose IN(0,1)),target TEXT,revision INTEGER NOT NULL,enabled INTEGER NOT NULL CHECK(enabled IN(0,1)),initialized INTEGER NOT NULL CHECK(initialized IN(0,1)),root_name TEXT NOT NULL,root_identity TEXT,FOREIGN KEY(workspace_id,context_id) REFERENCES output_contexts(workspace_id,id));
CREATE TABLE output_observations(location_id TEXT NOT NULL REFERENCES output_locations(id),path TEXT NOT NULL,sha256 TEXT NOT NULL,kept INTEGER NOT NULL CHECK(kept IN(0,1)),PRIMARY KEY(location_id,path));
CREATE TABLE profile_data_actions(id TEXT PRIMARY KEY,context_id TEXT NOT NULL REFERENCES profile_data_contexts(id),owner TEXT NOT NULL,busy INTEGER NOT NULL,complete INTEGER NOT NULL,body BLOB NOT NULL);
CREATE TABLE profile_data_contexts(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),documents_identity TEXT NOT NULL,revision INTEGER NOT NULL,pending TEXT,body BLOB NOT NULL);
CREATE TABLE profile_data_profiles(context_id TEXT NOT NULL REFERENCES profile_data_contexts(id),profile_id TEXT NOT NULL REFERENCES profiles(id),body BLOB NOT NULL,PRIMARY KEY(context_id,profile_id));
CREATE TABLE profile_mods(profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE, mod_id TEXT NOT NULL REFERENCES mods(id), priority INTEGER NOT NULL, enabled INTEGER, PRIMARY KEY(profile_id,mod_id), UNIQUE(profile_id,priority));
CREATE TABLE profiles (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL, selection_revision INTEGER NOT NULL DEFAULT 0);
CREATE TABLE root_creation_receipts (id TEXT PRIMARY KEY REFERENCES workspace_roots(id), owner TEXT NOT NULL, marker TEXT NOT NULL, revision INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 1 AND 4), busy INTEGER NOT NULL, abandoned INTEGER NOT NULL, marker_device_kind INTEGER, marker_device TEXT, marker_low TEXT, marker_high TEXT, detail TEXT NOT NULL);
CREATE TABLE skse_artifact_selections(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      game_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      checked_at TEXT NOT NULL
    );
CREATE TABLE skse_loader_selections(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      generation_id TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      source_checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id)
    );
CREATE TABLE skse_pending_handoffs(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      game_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      checked_at TEXT NOT NULL
    );
CREATE TABLE skse_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      game_version TEXT NOT NULL,
      component_version TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      nexus_file INTEGER,
      checked_at TEXT NOT NULL
    );
CREATE TABLE skse_replacement_intents(
      receipt_id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      expected_selection_revision INTEGER NOT NULL,
      previous_mod_id TEXT,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      generation_id TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      source_checked_at TEXT NOT NULL
    );
CREATE TABLE skyrim_setup_intents(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      include_fnis INTEGER NOT NULL CHECK(include_fnis IN (0,1)),
      plan_token TEXT NOT NULL,
      requested_at TEXT NOT NULL
    , cancelled INTEGER NOT NULL DEFAULT 0 CHECK(cancelled IN (0,1)), completed INTEGER NOT NULL DEFAULT 0 CHECK(completed IN (0,1)), stage TEXT NOT NULL DEFAULT 'setup', context_revision INTEGER NOT NULL DEFAULT 0, action_id TEXT, archive_path TEXT, cancel_requested INTEGER NOT NULL DEFAULT 0 CHECK(cancel_requested IN (0,1)), cancel_detail TEXT NOT NULL DEFAULT '');
CREATE TABLE version_nexus_origins(version_id TEXT NOT NULL REFERENCES mod_versions(id) ON DELETE CASCADE,manual INTEGER NOT NULL,game TEXT NOT NULL,nexus_mod INTEGER NOT NULL,file_id INTEGER NOT NULL,version TEXT NOT NULL,PRIMARY KEY(version_id,manual));
CREATE TABLE workspace_roots (id TEXT PRIMARY KEY, path TEXT NOT NULL, device_kind INTEGER NOT NULL, device TEXT NOT NULL, file_low TEXT NOT NULL, file_high TEXT NOT NULL, revision INTEGER NOT NULL);
CREATE TABLE workspaces (id TEXT PRIMARY KEY REFERENCES workspace_roots(id), name TEXT NOT NULL, revision INTEGER NOT NULL, selected_profile TEXT, catalogue_revision INTEGER NOT NULL DEFAULT 0);
CREATE INDEX archive_installations_workspace ON archive_installations(workspace_id,state);
CREATE INDEX artifacts_workspace ON artifacts(workspace_id,id);
CREATE INDEX category_children ON categories(workspace_id,parent_id,id);
CREATE UNIQUE INDEX category_sibling_name ON categories(workspace_id,COALESCE(parent_id,''),label) WHERE missing=0;
CREATE INDEX deployment_pending ON deployment_receipts(phase,sequence);
CREATE INDEX executable_presets_workspace ON executable_presets(workspace_id,id);
CREATE INDEX executable_runs_preset ON executable_runs(workspace_id,preset_id,sequence);
CREATE INDEX executable_runs_workspace ON executable_runs(workspace_id,sequence);
CREATE INDEX file_visibility_history ON file_visibility_changes(workspace_id,mod_id,version_id,path,id);
CREATE UNIQUE INDEX fnis_active_run ON fnis_runs(profile_id) WHERE busy=1;
CREATE INDEX fnis_artifact_cache ON fnis_artifact_selections(workspace_id,account_id,checked_at DESC);
CREATE INDEX fnis_run_history ON fnis_runs(profile_id,requested_at DESC);
CREATE INDEX game_contexts_by_workspace ON game_contexts(workspace_id,profile_id);
CREATE INDEX mods_by_category ON mod_categories(category_id,mod_id);
CREATE INDEX mods_by_workspace ON mods(workspace_id,id);
CREATE INDEX output_actions_pending ON output_actions(workspace_id,context_id,complete,id);
CREATE INDEX output_locations_context ON output_locations(workspace_id,context_id,id);
CREATE INDEX profile_data_actions_context ON profile_data_actions(context_id,complete,id);
CREATE INDEX profile_data_contexts_documents ON profile_data_contexts(documents_identity);
CREATE INDEX profile_data_contexts_workspace ON profile_data_contexts(workspace_id,id);
CREATE INDEX profiles_by_workspace ON profiles(workspace_id,id);
CREATE INDEX skse_artifact_compatibility ON skse_artifact_selections(workspace_id,account_id,game_sha256,checked_at DESC);
CREATE UNIQUE INDEX workspace_root_identity ON workspace_roots(device_kind,device,file_low,file_high);
CREATE TRIGGER mod_catalogue_insert AFTER INSERT ON mods BEGIN UPDATE workspaces SET catalogue_revision=catalogue_revision+1 WHERE id=NEW.workspace_id; END;
CREATE TRIGGER mod_catalogue_update AFTER UPDATE ON mods BEGIN UPDATE workspaces SET catalogue_revision=catalogue_revision+1 WHERE id=NEW.workspace_id; END;
PRAGMA application_id=1296253774;
PRAGMA user_version=1;
        """
