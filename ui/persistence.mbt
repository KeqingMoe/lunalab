///|
let app_state_dir_env_key = "LUNALAB_STATE_DIR"

///|
priv struct SettingsSnapshot {
  providers : Array[ProviderConfig]
  current_provider_id : String?
} derive(FromJson, ToJson)

///|
priv struct UiSnapshot {
  sidebar_width : Int
  sidebar_hidden : Bool
} derive(FromJson, ToJson)

///|
priv struct ConversationIndexSnapshot {
  conversation_order : Array[String]
  current_session_id : String?
  draft_session_id : String?
  next_session_id : Int
} derive(FromJson, ToJson)

///|
priv struct PersistedConversationSnapshot {
  id : String
  title : String
  auto_title : String?
  manual_title : Bool?
  tree : ChatTreeSnapshot
} derive(FromJson, ToJson)

///|
fn app_state_dir() -> String {
  match @env.get_env_var(app_state_dir_env_key) {
    Some(path) if !path.trim().is_blank() => path.trim().to_string()
    _ => default_app_state_dir()
  }
}

///|
fn default_app_state_dir() -> String {
  match @env.get_env_var("HOME") {
    Some(home) if !home.trim().is_blank() =>
      home.trim().to_string() + "/.lunalab"
    _ => ".lunalab"
  }
}

///|
fn settings_state_path() -> String {
  app_state_dir() + "/settings.json"
}

///|
fn ui_state_path() -> String {
  app_state_dir() + "/ui.json"
}

///|
fn conversation_index_path() -> String {
  app_state_dir() + "/index.json"
}

///|
fn conversations_dir() -> String {
  app_state_dir() + "/conversations"
}

///|
fn conversation_state_path(session_id : String) -> String {
  conversations_dir() + "/" + session_id + ".json"
}

///|
pub fn load_app_state_snapshot() -> AppStateSnapshot {
  let defaults = default_app_state_snapshot()
  let settings = load_settings_snapshot().unwrap_or(SettingsSnapshot::{
    providers: defaults.providers.map(clone_provider_config),
    current_provider_id: defaults.current_provider_id,
  })
  let ui = load_ui_snapshot().unwrap_or(UiSnapshot::{
    sidebar_width: defaults.sidebar_width,
    sidebar_hidden: defaults.sidebar_hidden,
  })
  let index = load_conversation_index_snapshot().unwrap_or(
    default_conversation_index_snapshot(),
  )
  let (conversations, draft) = load_persisted_conversations(index)
  sanitize_snapshot(AppStateSnapshot::{
    providers: settings.providers.map(clone_provider_config),
    current_provider_id: settings.current_provider_id,
    conversations,
    current_index: session_index_from_id(
      conversations,
      index.current_session_id,
    ),
    draft,
    sidebar_width: ui.sidebar_width,
    sidebar_hidden: ui.sidebar_hidden,
    next_session_id: index.next_session_id,
  })
}

///|
fn save_settings_state(snapshot : AppStateSnapshot) -> Unit {
  let snapshot = sanitize_snapshot(snapshot)
  ensure_app_state_dir()
  write_json_file(settings_state_path(), SettingsSnapshot::{
    providers: snapshot.providers.map(clone_provider_config),
    current_provider_id: snapshot.current_provider_id,
  })
}

///|
fn save_ui_state(snapshot : AppStateSnapshot) -> Unit {
  let snapshot = sanitize_snapshot(snapshot)
  ensure_app_state_dir()
  write_json_file(ui_state_path(), UiSnapshot::{
    sidebar_width: snapshot.sidebar_width,
    sidebar_hidden: snapshot.sidebar_hidden,
  })
}

///|
fn save_conversation_state(
  snapshot : AppStateSnapshot,
  changed_session_ids : Array[String],
  removed_session_ids? : Array[String],
) -> Unit {
  let snapshot = sanitize_snapshot(snapshot)
  ensure_conversations_dir()

  for session_id in dedupe_session_ids(changed_session_ids) {
    match find_record_by_session_id(snapshot, session_id) {
      Some(record) => save_conversation_record(record)
      None => ()
    }
  }

  save_conversation_index_state(snapshot)

  for session_id in dedupe_session_ids(removed_session_ids.unwrap_or([])) {
    if !snapshot_references_session(snapshot, session_id) {
      remove_session_file(session_id)
    }
  }
}

///|
fn load_settings_snapshot() -> SettingsSnapshot? {
  read_json_file(settings_state_path())
}

///|
fn load_ui_snapshot() -> UiSnapshot? {
  read_json_file(ui_state_path())
}

///|
fn load_conversation_index_snapshot() -> ConversationIndexSnapshot? {
  read_json_file(conversation_index_path())
}

///|
fn default_conversation_index_snapshot() -> ConversationIndexSnapshot {
  ConversationIndexSnapshot::{
    conversation_order: [],
    current_session_id: None,
    draft_session_id: None,
    next_session_id: 1,
  }
}

///|
fn load_persisted_conversations(
  index : ConversationIndexSnapshot,
) -> (Array[ConversationRecord], ConversationRecord?) {
  let conversations = []
  for session_id in index.conversation_order {
    match load_conversation_record(session_id) {
      Some(record) => conversations.push(record)
      None => ()
    }
  }

  let draft = match index.draft_session_id {
    Some(session_id) if !session_records_contain(conversations, session_id) =>
      load_conversation_record(session_id)
    _ => None
  }

  (conversations, draft)
}

///|
fn load_conversation_record(session_id : String) -> ConversationRecord? {
  let session_id = session_id.trim().to_string()
  guard !session_id.is_blank() else { None }

  let persisted : PersistedConversationSnapshot? = read_json_file(
    conversation_state_path(session_id),
  )
  match persisted {
    Some(snapshot) =>
      Some(ConversationRecord::{
        id: session_id,
        title: snapshot.title,
        auto_title: snapshot.auto_title,
        manual_title: snapshot.manual_title,
        tree: snapshot.tree,
      })
    None => None
  }
}

///|
fn save_conversation_record(record : ConversationRecord) -> Unit {
  write_json_file(conversation_state_path(record.id), PersistedConversationSnapshot::{
    id: record.id,
    title: record.title,
    auto_title: record.auto_title,
    manual_title: record.manual_title,
    tree: record.tree,
  })
}

///|
fn save_conversation_index_state(snapshot : AppStateSnapshot) -> Unit {
  write_json_file(conversation_index_path(), ConversationIndexSnapshot::{
    conversation_order: snapshot.conversations.map(record => record.id),
    current_session_id: current_session_id(snapshot),
    draft_session_id: snapshot.draft.map(record => record.id),
    next_session_id: snapshot.next_session_id,
  })
}

///|
fn current_session_id(snapshot : AppStateSnapshot) -> String? {
  match snapshot.current_index {
    Some(index) if index >= 0 && index < snapshot.conversations.length() =>
      Some(snapshot.conversations[index].id)
    _ => None
  }
}

///|
fn session_index_from_id(
  conversations : Array[ConversationRecord],
  session_id : String?,
) -> Int? {
  match session_id {
    Some(target) => {
      for index in 0..<conversations.length() {
        if conversations[index].id == target {
          return Some(index)
        }
      }
      None
    }
    None => None
  }
}

///|
fn session_records_contain(
  records : Array[ConversationRecord],
  session_id : String,
) -> Bool {
  for record in records {
    if record.id == session_id {
      return true
    }
  }
  false
}

///|
fn snapshot_references_session(
  snapshot : AppStateSnapshot,
  session_id : String,
) -> Bool {
  if session_records_contain(snapshot.conversations, session_id) {
    return true
  }

  match snapshot.draft {
    Some(record) => record.id == session_id
    None => false
  }
}

///|
fn find_record_by_session_id(
  snapshot : AppStateSnapshot,
  session_id : String,
) -> ConversationRecord? {
  for record in snapshot.conversations {
    if record.id == session_id {
      return Some(clone_conversation_record(record))
    }
  }

  match snapshot.draft {
    Some(record) if record.id == session_id =>
      Some(clone_conversation_record(record))
    _ => None
  }
}

///|
fn dedupe_session_ids(session_ids : Array[String]) -> Array[String] {
  let seen = Map::new()
  let deduped = []
  for session_id in session_ids {
    let session_id = session_id.trim().to_string()
    guard !session_id.is_blank() else { continue }
    guard !seen.contains(session_id) else { continue }
    seen.set(session_id, true)
    deduped.push(session_id)
  }
  deduped
}

///|
fn remove_session_file(session_id : String) -> Unit {
  ignore(try? @fs.remove_file(conversation_state_path(session_id)))
}

///|
fn ensure_app_state_dir() -> Unit {
  ensure_dir(app_state_dir())
}

///|
fn ensure_conversations_dir() -> Unit {
  ensure_app_state_dir()
  ensure_dir(conversations_dir())
}

///|
fn ensure_dir(path : String) -> Unit {
  if !@fs.path_exists(path) {
    ignore(try? @fs.create_dir(path))
  }
}

///|
fn[T : FromJson] read_json_file(path : String) -> T? {
  guard @fs.path_exists(path) else { None }

  let content_result : Result[String, _] = try? @fs.read_file_to_string(path)
  match content_result {
    Ok(content) => decode_json_content(content)
    Err(_) => None
  }
}

///|
fn[T : FromJson] decode_json_content(content : String) -> T? {
  let json_result : Result[Json, _] = try? @json.parse(content)
  match json_result {
    Ok(json) => {
      let value_result : Result[T, _] = try? @json.from_json(json)
      match value_result {
        Ok(value) => Some(value)
        Err(_) => None
      }
    }
    Err(_) => None
  }
}

///|
fn[T : ToJson] write_json_file(path : String, value : T) -> Unit {
  let content = value.to_json().stringify(indent=2)
  ignore(try? @fs.write_string_to_file(path, content))
}
