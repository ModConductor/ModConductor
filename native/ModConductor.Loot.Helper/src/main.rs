use std::{
    collections::HashSet,
    io::{self, Read},
    path::{Path, PathBuf},
    process::ExitCode,
};

use libloot::{EvalMode, Game, GameType, MergeMode, libloot_revision, libloot_version};
use serde::{Deserialize, Serialize};

const PROTOCOL: u32 = 1;
const HELPER_REVISION: &str = env!("CARGO_PKG_VERSION");
const INPUT_LIMIT: u64 = 4 * 1024 * 1024;
const PLUGIN_LIMIT: usize = 8192;
const MESSAGE_LIMIT: usize = 4096;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct Request {
    protocol: u32,
    operation: String,
    correlation_id: String,
    capability_id: String,
    staging_root: PathBuf,
    game_root: PathBuf,
    local_path: PathBuf,
    metadata_root: PathBuf,
    masterlist_path: PathBuf,
    prelude_path: PathBuf,
    userlist_path: Option<PathBuf>,
    plugins: Vec<String>,
    source_fingerprint: String,
    metadata_revision: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct Message {
    plugin: String,
    level: String,
    text: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct Move {
    plugin: String,
    current: usize,
    proposed: usize,
    reason: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct Response {
    protocol: u32,
    helper_revision: String,
    libloot_version: String,
    libloot_revision: String,
    correlation_id: String,
    capability_id: String,
    source_fingerprint: String,
    metadata_revision: String,
    current: Vec<String>,
    sorted: Vec<String>,
    moves: Vec<Move>,
    messages: Vec<Message>,
}

fn checked(path: &Path, root: &Path) -> Result<PathBuf, String> {
    let root = root
        .canonicalize()
        .map_err(|error| format!("The supplied root cannot be read: {error}"))?;
    let path = path
        .canonicalize()
        .map_err(|error| format!("A supplied path cannot be read: {error}"))?;
    if path.starts_with(&root) {
        Ok(path)
    } else {
        Err("A supplied path is outside its checked root.".into())
    }
}

fn message_text(message: &libloot::metadata::Message) -> String {
    libloot::metadata::select_message_content(message.content(), "en")
        .map(|content| content.text().to_owned())
        .unwrap_or_default()
}

fn validate_plugin_names(plugins: &[String]) -> Result<(), String> {
    if plugins.len() > PLUGIN_LIMIT {
        return Err("The plugin list exceeds its entry limit.".into());
    }

    let mut plugin_names = HashSet::with_capacity(plugins.len());
    for plugin in plugins {
        if plugin.is_empty()
            || plugin == "."
            || plugin == ".."
            || plugin.contains('/')
            || plugin.contains('\\')
            || Path::new(plugin).file_name().and_then(|name| name.to_str()) != Some(plugin)
        {
            return Err("A plugin name is not a single file name.".into());
        }
        if !plugin_names.insert(plugin.to_lowercase()) {
            return Err("The plugin list contains duplicate names.".into());
        }
    }

    Ok(())
}

fn execute(request: Request) -> Result<Response, String> {
    if request.protocol != PROTOCOL {
        return Err("The helper protocol version is not supported.".into());
    }
    if request.capability_id != "skyrim-se-steam" {
        return Err("The game capability is not supported.".into());
    }
    validate_plugin_names(&request.plugins)?;

    let game_root = checked(&request.game_root, &request.staging_root)?;
    let local_path = checked(&request.local_path, &request.staging_root)?;
    let masterlist = checked(&request.masterlist_path, &request.metadata_root)?;
    let prelude = checked(&request.prelude_path, &request.metadata_root)?;
    let userlist = request
        .userlist_path
        .as_deref()
        .map(|path| checked(path, &request.metadata_root))
        .transpose()?;

    let mut game = Game::with_local_path(GameType::SkyrimSE, &game_root, &local_path)
        .map_err(|error| format!("The private game projection is unavailable: {error}"))?;
    {
        let database = game.database();
        let mut database = database
            .write()
            .map_err(|_| "The metadata database is unavailable.".to_owned())?;
        database
            .load_masterlist_with_prelude(&masterlist, &prelude)
            .map_err(|error| format!("The LOOT metadata is invalid: {error}"))?;
        if let Some(path) = userlist.as_deref() {
            database
                .load_userlist(path)
                .map_err(|error| format!("The user metadata is invalid: {error}"))?;
        }
    }

    if request.operation == "validateMetadata" {
        return Ok(Response {
            protocol: PROTOCOL,
            helper_revision: HELPER_REVISION.into(),
            libloot_version: libloot_version(),
            libloot_revision: libloot_revision(),
            correlation_id: request.correlation_id,
            capability_id: request.capability_id,
            source_fingerprint: request.source_fingerprint,
            metadata_revision: request.metadata_revision,
            current: Vec::new(),
            sorted: Vec::new(),
            moves: Vec::new(),
            messages: Vec::new(),
        });
    }
    if request.operation != "sort" {
        return Err("The helper operation is not supported.".into());
    }

    game.load_current_load_order_state()
        .map_err(|error| format!("The private load-order state is unavailable: {error}"))?;
    let paths: Vec<PathBuf> = request
        .plugins
        .iter()
        .map(|name| game_root.join("Data").join(name))
        .collect();
    let path_refs: Vec<&Path> = paths.iter().map(PathBuf::as_path).collect();
    game.load_plugins(&path_refs)
        .map_err(|error| format!("The projected plugins cannot be read: {error}"))?;
    let names: Vec<&str> = request.plugins.iter().map(String::as_str).collect();
    let sorted = game
        .sort_plugins(&names)
        .map_err(|error| format!("The plugin order cannot be sorted: {error}"))?;

    let database = game.database();
    let database = database
        .read()
        .map_err(|_| "The metadata database is unavailable.".to_owned())?;
    let mut messages = Vec::new();
    for plugin in &request.plugins {
        if let Some(metadata) = database
            .plugin_metadata(plugin, MergeMode::WithUserMetadata, EvalMode::Evaluate)
            .map_err(|error| format!("Plugin metadata cannot be read: {error}"))?
        {
            for message in metadata.messages() {
                if messages.len() >= MESSAGE_LIMIT {
                    return Err("The LOOT messages exceed their entry limit.".into());
                }
                messages.push(Message {
                    plugin: plugin.clone(),
                    level: message.message_type().to_string(),
                    text: message_text(message),
                });
            }
        }
    }
    for message in database
        .general_messages(MergeMode::WithUserMetadata, EvalMode::Evaluate)
        .map_err(|error| format!("General metadata messages cannot be read: {error}"))?
    {
        if messages.len() >= MESSAGE_LIMIT {
            return Err("The LOOT messages exceed their entry limit.".into());
        }
        messages.push(Message {
            plugin: String::new(),
            level: message.message_type().to_string(),
            text: message_text(&message),
        });
    }

    let moves = sorted
        .iter()
        .enumerate()
        .filter_map(|(proposed, plugin)| {
            let current = request
                .plugins
                .iter()
                .position(|name| name.eq_ignore_ascii_case(plugin))?;
            (current != proposed).then(|| Move {
                plugin: plugin.clone(),
                current: current + 1,
                proposed: proposed + 1,
                reason: database
                    .plugin_metadata(plugin, MergeMode::WithUserMetadata, EvalMode::Evaluate)
                    .ok()
                    .flatten()
                    .and_then(|metadata| metadata.group().map(|group| format!("Group: {group}")))
                    .unwrap_or_else(|| "LOOT ordering constraints".into()),
            })
        })
        .collect();

    Ok(Response {
        protocol: PROTOCOL,
        helper_revision: HELPER_REVISION.into(),
        libloot_version: libloot_version(),
        libloot_revision: libloot_revision(),
        correlation_id: request.correlation_id,
        capability_id: request.capability_id,
        source_fingerprint: request.source_fingerprint,
        metadata_revision: request.metadata_revision,
        current: request.plugins,
        sorted,
        moves,
        messages,
    })
}

fn run() -> Result<(), String> {
    if std::env::args().nth(1).as_deref() == Some("--identity") {
        let response = Response {
            protocol: PROTOCOL,
            helper_revision: HELPER_REVISION.into(),
            libloot_version: libloot_version(),
            libloot_revision: libloot_revision(),
            correlation_id: String::new(),
            capability_id: "skyrim-se-steam".into(),
            source_fingerprint: String::new(),
            metadata_revision: String::new(),
            current: Vec::new(),
            sorted: Vec::new(),
            moves: Vec::new(),
            messages: Vec::new(),
        };
        serde_json::to_writer(io::stdout(), &response)
            .map_err(|error| format!("The helper identity cannot be written: {error}"))?;
        return Ok(());
    }
    let mut input = Vec::new();
    io::stdin()
        .take(INPUT_LIMIT + 1)
        .read_to_end(&mut input)
        .map_err(|error| format!("The helper request cannot be read: {error}"))?;
    if input.len() as u64 > INPUT_LIMIT {
        return Err("The helper request exceeds its byte limit.".into());
    }
    let request: Request = serde_json::from_slice(&input)
        .map_err(|error| format!("The helper request is invalid: {error}"))?;
    let response = execute(request)?;
    serde_json::to_writer(io::stdout(), &response)
        .map_err(|error| format!("The helper response cannot be written: {error}"))?;
    Ok(())
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::from(2)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::validate_plugin_names;

    #[test]
    fn accepts_single_plugin_file_names() {
        assert!(
            validate_plugin_names(&[
                "Skyrim.esm".to_owned(),
                "Unofficial Skyrim Special Edition Patch.esp".to_owned(),
            ])
            .is_ok()
        );
    }

    #[test]
    fn rejects_paths_and_case_insensitive_duplicates() {
        for plugin in ["../outside.esp", "folder/plugin.esp", "folder\\plugin.esp"] {
            assert!(validate_plugin_names(&[plugin.to_owned()]).is_err());
        }
        assert!(validate_plugin_names(&["Patch.esp".to_owned(), "PATCH.ESP".to_owned()]).is_err());
    }
}
