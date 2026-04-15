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

///|
test "manual conversation title is preserved after further mutations" {
  let session = new_conversation_session("session-1")
  ignore(session.tree.commit(Message::user("第一条消息")))
  session.refresh_title()
  assert_eq(session.title, "第一条消息")

  session.rename("手动标题")
  ignore(session.tree.commit(Message::assistant("助手回复")))
  session.refresh_title()

  assert_eq(session.title, "手动标题")
  assert_eq(session.auto_title, "第一条消息")
}

///|
test "current index shifts predictably after deleting a conversation" {
  assert_eq(current_index_after_conversation_removed(3, Some(2), 1), Some(1))
  assert_eq(current_index_after_conversation_removed(3, Some(1), 1), Some(1))
  assert_eq(current_index_after_conversation_removed(1, Some(0), 0), None)
}
