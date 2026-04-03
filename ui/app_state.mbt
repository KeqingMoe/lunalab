///|
pub(all) enum ProviderKind {
  OpenAICompatible
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct ProviderConfig {
  id : String
  name : String
  kind : ProviderKind
  base_url : String
  api_key : String
  model : String
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct ConversationRecord {
  title : String
  tree : ChatTreeSnapshot
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct AppStateSnapshot {
  providers : Array[ProviderConfig]
  current_provider_id : String?
  conversations : Array[ConversationRecord]
  current_index : Int?
  draft : ConversationRecord?
  sidebar_width : Int
  sidebar_hidden : Bool
} derive(FromJson, ToJson, Eq, Show)

///|
pub struct AppStateStore {
  mut snapshot : AppStateSnapshot
}

///|
pub fn default_provider() -> ProviderConfig {
  ProviderConfig::{
    id: "openrouter",
    name: "OpenRouter",
    kind: OpenAICompatible,
    base_url: "https://openrouter.ai/api/v1/chat/completions",
    api_key: default_openrouter_api_key(),
    model: "openai/gpt-4.1-mini",
  }
}

///|
pub fn default_app_state_snapshot() -> AppStateSnapshot {
  let provider = default_provider()
  AppStateSnapshot::{
    providers: [provider],
    current_provider_id: Some(provider.id),
    conversations: [],
    current_index: None,
    draft: Some(conversation_record_from_session(new_conversation_session())),
    sidebar_width: sidebar_default_width(),
    sidebar_hidden: false,
  }
}

///|
pub fn AppStateStore::new(snapshot? : AppStateSnapshot) -> Self {
  let base = sanitize_snapshot(snapshot.unwrap_or(default_app_state_snapshot()))
  AppStateStore::{ snapshot: base }
}

///|
pub fn AppStateStore::snapshot(self : Self) -> AppStateSnapshot {
  sanitize_snapshot(clone_snapshot(self.snapshot))
}

///|
pub fn AppStateStore::providers(self : Self) -> Array[ProviderConfig] {
  self.snapshot.providers.map(clone_provider_config)
}

///|
pub fn AppStateStore::current_provider_id(self : Self) -> String? {
  self.snapshot.current_provider_id
}

///|
pub fn AppStateStore::current_provider(self : Self) -> ProviderConfig? {
  match self.snapshot.current_provider_id {
    Some(provider_id) =>
      find_provider_by_id(self.snapshot.providers, provider_id)
    None => None
  }
}

///|
pub fn AppStateStore::set_providers(
  self : Self,
  providers : Array[ProviderConfig],
  current_provider_id : String?,
) -> Unit {
  self.snapshot = sanitize_snapshot(AppStateSnapshot::{
    providers: providers.map(clone_provider_config),
    current_provider_id,
    conversations: self.snapshot.conversations.map(clone_conversation_record),
    current_index: self.snapshot.current_index,
    draft: self.snapshot.draft.map(clone_conversation_record),
    sidebar_width: self.snapshot.sidebar_width,
    sidebar_hidden: self.snapshot.sidebar_hidden,
  })
}

///|
pub fn AppStateStore::conversation_sessions(
  self : Self,
) -> Array[ConversationSession] {
  self.snapshot.conversations.map(conversation_session_from_record)
}

///|
pub fn AppStateStore::current_index(self : Self) -> Int? {
  self.snapshot.current_index
}

///|
pub fn AppStateStore::draft_session(self : Self) -> ConversationSession? {
  self.snapshot.draft.map(conversation_session_from_record)
}

///|
pub fn AppStateStore::sidebar_width(self : Self) -> Int {
  self.snapshot.sidebar_width
}

///|
pub fn AppStateStore::sidebar_hidden(self : Self) -> Bool {
  self.snapshot.sidebar_hidden
}

///|
pub fn AppStateStore::set_conversation_state(
  self : Self,
  conversations : Array[ConversationSession],
  current_index : Int?,
  draft : ConversationSession?,
) -> Unit {
  self.snapshot = sanitize_snapshot(AppStateSnapshot::{
    providers: self.snapshot.providers.map(clone_provider_config),
    current_provider_id: self.snapshot.current_provider_id,
    conversations: conversations.map(conversation_record_from_session),
    current_index,
    draft: draft.map(conversation_record_from_session),
    sidebar_width: self.snapshot.sidebar_width,
    sidebar_hidden: self.snapshot.sidebar_hidden,
  })
}

///|
pub fn AppStateStore::set_sidebar_state(
  self : Self,
  width : Int,
  hidden : Bool,
) -> Unit {
  self.snapshot = sanitize_snapshot(AppStateSnapshot::{
    providers: self.snapshot.providers.map(clone_provider_config),
    current_provider_id: self.snapshot.current_provider_id,
    conversations: self.snapshot.conversations.map(clone_conversation_record),
    current_index: self.snapshot.current_index,
    draft: self.snapshot.draft.map(clone_conversation_record),
    sidebar_width: width,
    sidebar_hidden: hidden,
  })
}

///|
fn sanitize_snapshot(snapshot : AppStateSnapshot) -> AppStateSnapshot {
  let providers = sanitize_providers(snapshot.providers)
  let current_provider_id = sanitize_current_provider_id(
    providers,
    snapshot.current_provider_id,
  )
  let conversations = snapshot.conversations.map(clone_conversation_record)
  let current_index = sanitize_current_index(
    conversations.length(),
    snapshot.current_index,
  )
  let draft = sanitize_draft(
    snapshot.draft,
    conversations.length(),
    current_index,
  )
  AppStateSnapshot::{
    providers,
    current_provider_id,
    conversations,
    current_index,
    draft,
    sidebar_width: snapshot.sidebar_width.clamp(
      min=sidebar_min_width(),
      max=sidebar_max_width(),
    ),
    sidebar_hidden: snapshot.sidebar_hidden,
  }
}

///|
fn sanitize_providers(
  providers : Array[ProviderConfig],
) -> Array[ProviderConfig] {
  let sanitized = dedupe_providers(
    providers
    .map(clone_provider_config)
    .filter(provider => !provider.id.trim().is_blank()),
  )
  guard sanitized.length() > 0 else { [default_provider()] }
  sanitized
}

///|
fn sanitize_current_provider_id(
  providers : Array[ProviderConfig],
  current_provider_id : String?,
) -> String? {
  match current_provider_id {
    Some(provider_id) if find_provider_by_id(providers, provider_id) is Some(_) =>
      Some(provider_id)
    _ => Some(providers[0].id)
  }
}

///|
fn sanitize_current_index(total : Int, current_index : Int?) -> Int? {
  match current_index {
    Some(index) if index >= 0 && index < total => Some(index)
    _ => None
  }
}

///|
fn sanitize_draft(
  draft : ConversationRecord?,
  conversation_count : Int,
  current_index : Int?,
) -> ConversationRecord? {
  match draft {
    Some(record) => Some(clone_conversation_record(record))
    None =>
      match current_index {
        None =>
          Some(conversation_record_from_session(new_conversation_session()))
        Some(_) =>
          if conversation_count == 0 {
            Some(conversation_record_from_session(new_conversation_session()))
          } else {
            None
          }
      }
  }
}

///|
fn dedupe_providers(providers : Array[ProviderConfig]) -> Array[ProviderConfig] {
  let seen = Map::new()
  let deduped = []
  for provider in providers {
    guard !seen.contains(provider.id) else { continue }
    seen.set(provider.id, true)
    deduped.push(normalize_provider_config(provider))
  }
  deduped
}

///|
fn normalize_provider_config(provider : ProviderConfig) -> ProviderConfig {
  ProviderConfig::{
    id: provider.id.trim().to_string(),
    name: if provider.name.trim().is_blank() {
      provider.id.trim().to_string()
    } else {
      provider.name.trim().to_string()
    },
    kind: provider.kind,
    base_url: provider.base_url.trim().to_string(),
    api_key: provider.api_key,
    model: provider.model.trim().to_string(),
  }
}

///|
fn find_provider_by_id(
  providers : Array[ProviderConfig],
  provider_id : String,
) -> ProviderConfig? {
  for provider in providers {
    if provider.id == provider_id {
      return Some(clone_provider_config(provider))
    }
  }
  None
}

///|
fn conversation_record_from_session(
  session : ConversationSession,
) -> ConversationRecord {
  ConversationRecord::{ title: session.title, tree: session.tree.snapshot() }
}

///|
fn conversation_session_from_record(
  record : ConversationRecord,
) -> ConversationSession {
  ConversationSession::{
    title: normalize_conversation_title(record.title),
    tree: ChatTree::from_snapshot(record.tree),
  }
}

///|
fn clone_provider_config(provider : ProviderConfig) -> ProviderConfig {
  ProviderConfig::{
    id: provider.id,
    name: provider.name,
    kind: provider.kind,
    base_url: provider.base_url,
    api_key: provider.api_key,
    model: provider.model,
  }
}

///|
fn clone_conversation_record(record : ConversationRecord) -> ConversationRecord {
  ConversationRecord::{ title: record.title, tree: record.tree }
}

///|
fn clone_snapshot(snapshot : AppStateSnapshot) -> AppStateSnapshot {
  AppStateSnapshot::{
    providers: snapshot.providers.map(clone_provider_config),
    current_provider_id: snapshot.current_provider_id,
    conversations: snapshot.conversations.map(clone_conversation_record),
    current_index: snapshot.current_index,
    draft: snapshot.draft.map(clone_conversation_record),
    sidebar_width: snapshot.sidebar_width,
    sidebar_hidden: snapshot.sidebar_hidden,
  }
}

///|
fn default_openrouter_api_key() -> String {
  match @env.get_env_var("OPENROUTER_API_KEY") {
    Some(value) => value
    None => ""
  }
}
