///|
test "chat tree commit keeps current path history" {
  let tree = ChatTree::new()
  let system_id = tree.commit(Message::system("system"))
  let user_id = tree.commit(Message::user("hello"))
  let assistant_id = tree.commit(Message::assistant("world"))

  assert_eq(system_id, "node-0")
  assert_eq(user_id, "node-1")
  assert_eq(assistant_id, "node-2")
  assert_eq(tree.history_messages(), [
    Message::system("system"),
    Message::user("hello"),
    Message::assistant("world"),
  ])
  assert_eq(tree.path_to(assistant_id), ["node-0", "node-1", "node-2"])
}

///|
test "edit user creates sibling branch from original parent" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("draft"))
  let _assistant_id = tree.commit(Message::assistant("answer"))

  let edited_user_id = tree.edit_user_node(user_id, "revised").unwrap()
  let children = tree.get_children(tree.root_id().unwrap())

  assert_eq(children.map(node => node.id), [user_id, edited_user_id])
  assert_eq(tree.path_to(edited_user_id), ["node-0", edited_user_id])

  let edited_user = tree.get_node(edited_user_id).unwrap()
  assert_eq(edited_user.op, Edit)
  assert_eq(edited_user.origin_node_id, Some(user_id))
}

///|
test "retry assistant adds alternate answer under same user" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("question"))
  let first_assistant_id = tree.commit(Message::assistant("first"))
  let second_assistant_id = tree.retry_assistant(user_id, "second")

  let user_children = tree.get_children(user_id)
  assert_eq(user_children.map(node => node.id), [
    first_assistant_id, second_assistant_id,
  ])

  let second_assistant = tree.get_node(second_assistant_id).unwrap()
  assert_eq(second_assistant.op, Retry)
  assert_eq(second_assistant.author_type, Model)
  assert_eq(second_assistant.origin_node_id, Some(user_id))
}

///|
test "insert child can attach arbitrary node and move head" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("question"))
  let assistant_id = tree.commit(Message::assistant("answer"))
  let imported_id = tree.insert_child(
    user_id,
    NodeInsert::new(
      Message::assistant("imported"),
      author_type=Human,
      op=Import,
      metadata=Map::from_array([("source", "manual")]),
    ),
  )

  assert_eq(tree.head_id(), Some(imported_id))
  assert_eq(tree.move_head(assistant_id), true)
  assert_eq(tree.head_id(), Some(assistant_id))

  let imported = tree.get_node(imported_id).unwrap()
  assert_eq(imported.metadata.get("source"), Some("manual"))
  assert_eq(imported.op, Import)
}

///|
test "compact range replaces hidden span in built context" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("u1"))
  let assistant_id = tree.commit(Message::assistant("a1"))
  let tail_user_id = tree.commit(Message::user("u2"))
  let tail_assistant_id = tree.commit(Message::assistant("a2"))

  let summary_id = tree.compact_range(user_id, assistant_id, "summary").unwrap()

  assert_eq(tree.history_messages(), [
    Message::system("system"),
    Message::user("u1"),
    Message::assistant("a1"),
    Message::user("u2"),
    Message::assistant("a2"),
  ])
  assert_eq(tree.context_node_ids(tail_assistant_id), [
    "node-0", summary_id, tail_user_id, tail_assistant_id,
  ])
  assert_eq(tree.build_context(tail_assistant_id), [
    Message::system("system"),
    Message::system("summary"),
    Message::user("u2"),
    Message::assistant("a2"),
  ])

  let compacted_user = tree.get_node(user_id).unwrap()
  let compacted_assistant = tree.get_node(assistant_id).unwrap()
  assert_eq(compacted_user.status, Compacted)
  assert_eq(compacted_assistant.status, Compacted)
}

///|
test "snapshot roundtrip preserves context and compact spans" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("u1"))
  let assistant_id = tree.commit(Message::assistant("a1"))
  let tail_user_id = tree.commit(Message::user("u2"))
  let tail_assistant_id = tree.commit(Message::assistant("a2"))
  let summary_id = tree.compact_range(user_id, assistant_id, "summary").unwrap()

  let snapshot = tree.snapshot()
  let restored = ChatTree::from_snapshot(snapshot)

  assert_eq(restored.head_id(), tree.head_id())
  assert_eq(restored.context_node_ids(tail_assistant_id), [
    "node-0", summary_id, tail_user_id, tail_assistant_id,
  ])
  assert_eq(restored.compact_spans().length(), 1)
}

///|
test "json roundtrip preserves snapshot" {
  let tree = ChatTree::new(root_message=Message::system("system"))
  let user_id = tree.commit(Message::user("u1"))
  let assistant_id = tree.commit(Message::assistant("a1"))
  let _ = tree.compact_range(user_id, assistant_id, "summary")

  let restored = ChatTree::from_json(tree.to_json())
  assert_eq(restored.snapshot(), tree.snapshot())
}
