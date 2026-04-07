///|
test "default app state has a selected provider and draft" {
  let snapshot = default_app_state_snapshot()

  assert_eq(snapshot.providers.length(), 1)
  assert_eq(snapshot.current_provider_id, Some("openrouter"))
  assert_true(snapshot.draft is Some(_))
}

///|
test "app state store sanitizes missing current provider" {
  let snapshot = AppStateSnapshot::{
    providers: [
      ProviderConfig::{
        id: "alpha",
        name: "Alpha",
        kind: OpenAICompatible,
        base_url: "https://example.com/v1/chat/completions",
        api_key: "sk-alpha",
        model: "gpt-4.1-mini",
      },
    ],
    current_provider_id: Some("missing"),
    conversations: [],
    current_index: None,
    draft: None,
    sidebar_width: 12,
    sidebar_hidden: false,
    next_session_id: 0,
  }

  let store = AppStateStore::new(snapshot~)
  assert_eq(store.current_provider_id(), Some("alpha"))
  assert_eq(store.sidebar_width(), sidebar_min_width())
  assert_true(store.draft_session() is Some(_))
}

///|
test "provider request helpers validate config and parse response" {
  let provider = ProviderConfig::{
    id: "demo",
    name: "Demo",
    kind: OpenAICompatible,
    base_url: "https://example.com/v1/chat/completions",
    api_key: "sk-demo",
    model: "demo-model",
  }

  assert_eq(provider_missing_config_message(Some(provider)), None)
  assert_eq(
    extract_provider_response_text(
      (
        #|{"choices":[{"message":{"content":"hello"}}]}
      ),
    ),
    "hello",
  )
  assert_true(
    provider_failure_message(
      provider,
      401,
      "Unauthorized",
      "auth failed",
      (
        #|{"error":{"message":"bad key"}}
      ),
    ).contains("bad key"),
  )
}
