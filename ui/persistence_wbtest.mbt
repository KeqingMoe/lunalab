///|
test "load ignores legacy state json and returns default draft id" {
  let dir = ".lunalab-test-ignore-legacy"
  with_test_state_dir(dir, fn() raise {
    write_text_file(
      dir + "/state.json",
      (
        #|{"providers":[{"id":"legacy","name":"Legacy","kind":"OpenAICompatible","base_url":"https://example.com","api_key":"legacy","model":"legacy"}],"current_provider_id":"legacy","conversations":[],"current_index":null,"draft":null,"sidebar_width":999,"sidebar_hidden":true}
      ),
    )

    let snapshot = load_app_state_snapshot()
    assert_eq(snapshot.current_provider_id, Some("openrouter"))
    assert_eq(snapshot.sidebar_width, sidebar_default_width())
    assert_eq(snapshot.sidebar_hidden, false)
    assert_eq(snapshot.draft.map(record => record.id), Some("session-1"))
  })
}

///|
test "load aggregates split persistence files and repairs invalid references" {
  let dir = ".lunalab-test-load-split"
  with_test_state_dir(dir, fn() raise {
    ensure_dir_for_test(dir)
    ensure_dir_for_test(dir + "/conversations")

    write_json_fixture(
      dir + "/settings.json",
      (
        #|{
        #|  "providers": [
        #|    {
        #|      "id": "demo",
        #|      "name": "Demo",
        #|      "kind": "OpenAICompatible",
        #|      "base_url": "https://example.com/v1/chat/completions",
        #|      "api_key": "sk-demo",
        #|      "model": "demo-model"
        #|    }
        #|  ],
        #|  "current_provider_id": "missing"
        #|}
      ),
    )
    write_json_fixture(
      dir + "/ui.json",
      (
        #|{"sidebar_width":12,"sidebar_hidden":true}
      ),
    )
    write_json_fixture(
      dir + "/index.json",
      (
        #|{
        #|  "conversation_order": ["session-2", "session-9"],
        #|  "current_session_id": "session-9",
        #|  "draft_session_id": "session-3",
        #|  "next_session_id": 1
        #|}
      ),
    )
    write_json_fixture(
      dir + "/conversations/session-2.json",
      persisted_conversation_fixture("session-2", "Alpha", "hello", "world"),
    )
    write_json_fixture(
      dir + "/conversations/session-3.json",
      persisted_conversation_fixture(
        "session-3", "Draft", "draft user", "draft assistant",
      ),
    )

    let snapshot = load_app_state_snapshot()
    assert_eq(snapshot.providers.length(), 1)
    assert_eq(snapshot.current_provider_id, Some("demo"))
    assert_eq(snapshot.sidebar_width, sidebar_min_width())
    assert_eq(snapshot.sidebar_hidden, true)
    assert_eq(snapshot.conversations.length(), 1)
    assert_eq(snapshot.conversations[0].id, "session-2")
    assert_eq(snapshot.current_index, None)
    assert_eq(snapshot.draft.map(record => record.id), Some("session-3"))
    assert_eq(snapshot.next_session_id, 4)
  })
}

///|
test "conversation save writes changed files and cleans removed draft file" {
  let dir = ".lunalab-test-save-conversation"
  with_test_state_dir(dir, fn() raise {
    let store = AppStateStore::new()
    let conversation = store.new_session()
    conversation.tree.commit(Message::user("first")) |> ignore
    conversation.tree.commit(Message::assistant("reply")) |> ignore
    conversation.refresh_title()

    let new_draft = store.new_session()
    let snapshot = AppStateSnapshot::{
      providers: store.providers(),
      current_provider_id: store.current_provider_id(),
      conversations: [conversation_record_from_session(conversation)],
      current_index: Some(0),
      draft: Some(conversation_record_from_session(new_draft)),
      sidebar_width: sidebar_default_width(),
      sidebar_hidden: false,
      next_session_id: store.snapshot().next_session_id,
    }

    save_conversation_state(snapshot, [conversation.id, new_draft.id], removed_session_ids=[
      "session-1",
    ])

    let files = try! @fs.read_dir(dir + "/conversations")
    assert_true(files.contains(conversation.id + ".json"))
    assert_true(files.contains(new_draft.id + ".json"))
    assert_true(!files.contains("session-1.json"))

    let index = try! @fs.read_file_to_string(dir + "/index.json")
    assert_true(index.contains(conversation.id))
    assert_true(index.contains(new_draft.id))
  })
}

///|
test "settings and ui saves stay in their own files" {
  let dir = ".lunalab-test-save-settings-ui"
  with_test_state_dir(dir, fn() raise {
    let snapshot = default_app_state_snapshot()
    save_settings_state(snapshot)
    save_ui_state(snapshot)

    assert_true(@fs.path_exists(dir + "/settings.json"))
    assert_true(@fs.path_exists(dir + "/ui.json"))
    assert_true(!@fs.path_exists(dir + "/index.json"))
    assert_true(!@fs.path_exists(dir + "/conversations"))
  })
}

///|
fn[T] with_test_state_dir(dir : String, action : () -> T raise) -> T raise {
  cleanup_test_state_dir(dir)
  @env.set_env_var(app_state_dir_env_key, dir)
  let result = action()
  @env.unset_env_var(app_state_dir_env_key)
  cleanup_test_state_dir(dir)
  result
}

///|
fn cleanup_test_state_dir(dir : String) -> Unit {
  if @fs.path_exists(dir + "/conversations") {
    let files : Result[Array[String], _] = try? @fs.read_dir(
      dir + "/conversations",
    )
    match files {
      Ok(files) =>
        for file in files {
          ignore(try? @fs.remove_file(dir + "/conversations/" + file))
        }
      Err(_) => ()
    }
    ignore(try? @fs.remove_dir(dir + "/conversations"))
  }

  for path in ["/settings.json", "/ui.json", "/index.json", "/state.json"] {
    ignore(try? @fs.remove_file(dir + path))
  }
  ignore(try? @fs.remove_dir(dir))
}

///|
fn ensure_dir_for_test(path : String) -> Unit {
  if !@fs.path_exists(path) {
    try! @fs.create_dir(path)
  }
}

///|
fn write_text_file(path : String, content : String) -> Unit {
  let parts = path.split("/").map(StringView::to_string).to_array()
  if parts.length() > 1 {
    let dir = parts[0]
    ensure_dir_for_test(dir)
    if parts.length() > 2 {
      ensure_dir_for_test(dir + "/" + parts[1])
    }
  }
  try! @fs.write_string_to_file(path, content)
}

///|
fn write_json_fixture(path : String, content : String) -> Unit {
  write_text_file(path, content)
}

///|
fn persisted_conversation_fixture(
  id : String,
  title : String,
  user_content : String,
  assistant_content : String,
) -> String {
  PersistedConversationSnapshot::{
    id,
    title,
    auto_title: Some(title),
    manual_title: Some(false),
    tree: conversation_tree_snapshot(user_content, assistant_content),
  }
  .to_json()
  .stringify(indent=2)
}

///|
fn conversation_tree_snapshot(
  user_content : String,
  assistant_content : String,
) -> ChatTreeSnapshot {
  let tree = ChatTree::new()
  tree.commit(Message::user(user_content)) |> ignore
  tree.commit(Message::assistant(assistant_content)) |> ignore
  tree.snapshot()
}
