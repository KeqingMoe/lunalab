///|
struct ConversationSession {
  id : String
  mut title : String
  mut auto_title : String
  mut manual_title : Bool
  tree : ChatTree
}

///|
enum ComposerMode {
  Auto
  Append
}

///|
fn new_chat_tree() -> ChatTree {
  ChatTree::new()
}

///|
fn new_conversation_session(id : String) -> ConversationSession {
  let title = default_conversation_title()
  ConversationSession::{
    id,
    title,
    auto_title: title,
    manual_title: false,
    tree: new_chat_tree(),
  }
}

///|
fn conversation_titles(
  conversations : Array[ConversationSession],
) -> Array[String] {
  conversations.map(x => x.title)
}

///|
fn conversation_titles_for_sidebar(
  conversations : Array[ConversationSession],
) -> Array[String] {
  let titles = conversation_titles(conversations)
  titles.rev_in_place()
  titles
}

///|
fn default_conversation_title() -> String {
  "新对话"
}

///|
fn conversation_messages(tree : ChatTree) -> Array[Message] {
  tree.history_messages()
}

///|
fn conversation_node_ids(tree : ChatTree) -> Array[String] {
  match tree.head_id() {
    Some(head_id) => tree.path_to(head_id)
    None => []
  }
}

///|
fn conversation_has_messages(tree : ChatTree) -> Bool {
  conversation_messages(tree).length() > 0
}

///|
fn conversation_title_from_tree(tree : ChatTree) -> String {
  let messages = conversation_messages(tree)

  for msg in messages {
    if msg.role is User {
      let title = normalize_conversation_title(msg.content)
      if !title.is_blank() {
        return title
      }
    }
  }

  for msg in messages {
    if msg.role is Assistant {
      let title = normalize_conversation_title(msg.content)
      if !title.is_blank() {
        return title
      }
    }
  }

  for msg in messages {
    if msg.role is System {
      let title = normalize_conversation_title(msg.content)
      if !title.is_blank() {
        return title
      }
    }
  }

  default_conversation_title()
}

///|
fn normalize_conversation_title(text : String) -> String {
  let normalized = text.split("\r\n").map(StringView::to_string).join("\n")
  for line in normalized.split("\n") {
    let title = line.trim().to_string()
    if !title.is_blank() {
      return title
    }
  }
  default_conversation_title()
}

///|
fn ConversationSession::refresh_title(self : Self) -> Unit {
  let next_title = conversation_title_from_tree(self.tree)
  if !self.manual_title {
    self.title = next_title
  }
  self.auto_title = next_title
}

///|
fn ConversationSession::rename(self : Self, title : String) -> Unit {
  self.title = normalize_conversation_title(title)
  self.manual_title = true
}

///|
fn sidebar_display_index(total : Int, current_index : Int?) -> Int? {
  match current_index {
    Some(index) => Some(total - index - 1)
    None => None
  }
}

///|
fn sidebar_model_index(total : Int, display_index : Int) -> Int? {
  guard display_index >= 0 else { None }
  guard display_index < total else { None }
  Some(total - display_index - 1)
}

///|
fn move_conversation_to_end(
  conversations : Array[ConversationSession],
  index : Int,
) -> Int {
  guard index >= 0 else { index }
  guard index < conversations.length() else { index }
  guard index + 1 < conversations.length() else { index }

  let session = conversations.remove(index)
  conversations.push(session)
  conversations.length() - 1
}

///|
fn current_index_after_conversation_removed(
  total : Int,
  current_index : Int?,
  removed_index : Int,
) -> Int? {
  guard removed_index >= 0 else { current_index }
  guard removed_index < total else { current_index }

  let next_total = total - 1
  guard next_total > 0 else { None }

  match current_index {
    Some(index) if index == removed_index =>
      Some(removed_index.min(next_total - 1))
    Some(index) if index > removed_index => Some(index - 1)
    Some(index) if index >= 0 && index < total => Some(index)
    _ => None
  }
}

///|
fn head_hint(tree : ChatTree) -> String {
  let messages = conversation_messages(tree)
  guard messages.length() > 0 else { "当前：新对话草稿" }

  let head = messages[messages.length() - 1]
  let role = readable_role(head.role)
  let count = messages.length()
  "当前：\{role} · 共 \{count} 条消息"
}

///|
fn readable_role(role : Role) -> String {
  match role {
    System => "系统消息"
    User => "用户消息"
    Assistant => "助手消息"
  }
}
