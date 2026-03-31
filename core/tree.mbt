///|
pub type NodeId = String

///|
pub(all) enum AuthorType {
  Human
  Model
  SystemAuthor
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) enum NodeOp {
  Normal
  Edit
  Retry
  Compact
  Import
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) enum NodeStatus {
  NormalStatus
  Stale
  Hidden
  Compacted
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct ChatNode {
  id : NodeId
  mut parent_id : NodeId?
  child_ids : Array[NodeId]
  message : Message
  author_type : AuthorType
  op : NodeOp
  origin_node_id : NodeId?
  mut status : NodeStatus
  metadata : Map[String, String]
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct CompactSpan {
  start_node_id : NodeId
  end_node_id : NodeId
  summary_node_id : NodeId
  hidden_node_ids : Array[NodeId]
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct NodeInsert {
  message : Message
  author_type : AuthorType
  op : NodeOp
  origin_node_id : NodeId?
  status : NodeStatus
  metadata : Map[String, String]
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct ChatTreeSnapshot {
  next_id : Int
  root_id : NodeId?
  head_id : NodeId?
  nodes : Array[ChatNode]
  compact_spans : Array[CompactSpan]
} derive(FromJson, ToJson, Eq, Show)

///|
pub struct ChatTree {
  mut next_id : Int
  mut root_id : NodeId?
  mut head_id : NodeId?
  nodes : Map[NodeId, ChatNode]
  compact_spans : Array[CompactSpan]
}

///|
pub fn NodeInsert::new(
  message : Message,
  author_type? : AuthorType,
  op? : NodeOp,
  origin_node_id? : NodeId,
  status? : NodeStatus,
  metadata? : Map[String, String],
) -> Self {
  NodeInsert::{
    message,
    author_type: author_type.unwrap_or(default_author_type(message.role)),
    op: op.unwrap_or(Normal),
    origin_node_id,
    status: status.unwrap_or(NormalStatus),
    metadata: metadata.unwrap_or(Map::new()),
  }
}

///|
pub fn ChatTree::new(root_message? : Message) -> Self {
  let tree = ChatTree::{
    next_id: 0,
    root_id: None,
    head_id: None,
    nodes: Map::new(),
    compact_spans: [],
  }

  match root_message {
    Some(message) => {
      let root_id = tree.insert(None, NodeInsert::new(message))
      tree.root_id = Some(root_id)
      tree.head_id = Some(root_id)
    }
    None => ()
  }

  tree
}

///|
pub fn ChatTree::from_snapshot(snapshot : ChatTreeSnapshot) -> Self {
  let nodes = Map::new(capacity=snapshot.nodes.length())
  for node in snapshot.nodes {
    nodes.set(node.id, clone_node(node))
  }
  ChatTree::{
    next_id: snapshot.next_id,
    root_id: snapshot.root_id,
    head_id: snapshot.head_id,
    nodes,
    compact_spans: snapshot.compact_spans.map(clone_compact_span),
  }
}

///|
pub fn ChatTree::snapshot(self : Self) -> ChatTreeSnapshot {
  ChatTreeSnapshot::{
    next_id: self.next_id,
    root_id: self.root_id,
    head_id: self.head_id,
    nodes: collect_nodes(self.nodes),
    compact_spans: self.compact_spans.map(clone_compact_span),
  }
}

///|
pub fn ChatTree::to_json(self : Self) -> Json {
  self.snapshot().to_json()
}

///|
pub fn ChatTree::from_json(json : Json) -> Self raise @json.JsonDecodeError {
  ChatTree::from_snapshot(@json.from_json(json))
}

///|
pub fn ChatTree::commit(self : Self, message : Message) -> NodeId {
  match self.head_id {
    Some(parent_id) => self.append_after(parent_id, message)
    None => {
      let node_id = self.insert(None, NodeInsert::new(message))
      self.root_id = Some(node_id)
      self.head_id = Some(node_id)
      node_id
    }
  }
}

///|
pub fn ChatTree::append_after(
  self : Self,
  parent_id : NodeId,
  message : Message,
  author_type? : AuthorType,
  op? : NodeOp,
  origin_node_id? : NodeId,
  status? : NodeStatus,
  metadata? : Map[String, String],
) -> NodeId {
  self.insert(
    Some(parent_id),
    NodeInsert::new(
      message,
      author_type?,
      op?,
      origin_node_id?,
      status?,
      metadata?,
    ),
  )
}

///|
pub fn ChatTree::insert_child(
  self : Self,
  parent_id : NodeId,
  spec : NodeInsert,
) -> NodeId {
  self.insert(Some(parent_id), spec)
}

///|
pub fn ChatTree::insert_root(self : Self, spec : NodeInsert) -> NodeId {
  guard self.root_id is None else { self.root_id.unwrap() }
  let root_id = self.insert(None, spec)
  self.root_id = Some(root_id)
  self.head_id = Some(root_id)
  root_id
}

///|
pub fn ChatTree::retry_assistant(
  self : Self,
  user_node_id : NodeId,
  content : String,
) -> NodeId {
  self.append_after(
    user_node_id,
    Message::assistant(content),
    author_type=Model,
    op=Retry,
    origin_node_id=user_node_id,
  )
}

///|
pub fn ChatTree::edit_user_node(
  self : Self,
  node_id : NodeId,
  new_content : String,
) -> NodeId? {
  match self.get_node(node_id) {
    Some(node) if node.message.role is User =>
      match node.parent_id {
        Some(parent_id) =>
          Some(
            self.append_after(
              parent_id,
              Message::user(new_content),
              author_type=Human,
              op=Edit,
              origin_node_id=node_id,
            ),
          )
        None => None
      }
    _ => None
  }
}

///|
pub fn ChatTree::edit_assistant_node(
  self : Self,
  node_id : NodeId,
  new_content : String,
) -> NodeId? {
  match self.get_node(node_id) {
    Some(node) if node.message.role is Assistant =>
      match node.parent_id {
        Some(parent_id) =>
          Some(
            self.append_after(
              parent_id,
              Message::assistant(new_content),
              author_type=Human,
              op=Edit,
              origin_node_id=node_id,
            ),
          )
        None => None
      }
    _ => None
  }
}

///|
pub fn ChatTree::move_head(self : Self, node_id : NodeId) -> Bool {
  guard self.nodes.contains(node_id) else { false }
  self.head_id = Some(node_id)
  true
}

///|
pub fn ChatTree::head_id(self : Self) -> NodeId? {
  self.head_id
}

///|
pub fn ChatTree::root_id(self : Self) -> NodeId? {
  self.root_id
}

///|
pub fn ChatTree::node_count(self : Self) -> Int {
  self.nodes.length()
}

///|
pub fn ChatTree::history_messages(self : Self) -> Array[Message] {
  match self.head_id {
    Some(head_id) => self.path_nodes(head_id).map(node_to_message)
    None => []
  }
}

///|
pub fn ChatTree::context_messages(self : Self) -> Array[Message] {
  match self.head_id {
    Some(head_id) => self.build_context(head_id)
    None => []
  }
}

///|
pub fn ChatTree::build_context(self : Self, head_id : NodeId) -> Array[Message] {
  self.context_nodes(head_id).map(node_to_message)
}

///|
pub fn ChatTree::context_node_ids(
  self : Self,
  head_id : NodeId,
) -> Array[NodeId] {
  self.context_nodes(head_id).map(node => node.id)
}

///|
pub fn ChatTree::path_to(self : Self, node_id : NodeId) -> Array[NodeId] {
  self.path_nodes(node_id).map(node => node.id)
}

///|
pub fn ChatTree::get_node(self : Self, node_id : NodeId) -> ChatNode? {
  self.nodes.get(node_id).map(clone_node)
}

///|
pub fn ChatTree::get_children(self : Self, node_id : NodeId) -> Array[ChatNode] {
  match self.nodes.get(node_id) {
    Some(node) =>
      node.child_ids.filter_map(id => self.nodes.get(id).map(clone_node))
    None => []
  }
}

///|
pub fn ChatTree::compact_spans(self : Self) -> Array[CompactSpan] {
  self.compact_spans.map(clone_compact_span)
}

///|
pub fn ChatTree::compact_range(
  self : Self,
  start_node_id : NodeId,
  end_node_id : NodeId,
  summary_content : String,
  metadata? : Map[String, String],
) -> NodeId? {
  let hidden_node_ids = self.path_between(start_node_id, end_node_id)
  guard hidden_node_ids.length() > 0 else { None }

  let start_node = self.nodes.get(start_node_id).unwrap()
  guard start_node.parent_id is Some(parent_id) else { None }
  let current_head_id = self.head_id

  let summary_metadata = metadata.unwrap_or(Map::new())
  summary_metadata.set("compact_start_id", start_node_id)
  summary_metadata.set("compact_end_id", end_node_id)

  let summary_id = self.insert(
    Some(parent_id),
    NodeInsert::new(
      Message::system(summary_content),
      author_type=SystemAuthor,
      op=Compact,
      origin_node_id=end_node_id,
      metadata=summary_metadata,
    ),
  )

  for node_id in hidden_node_ids {
    match self.nodes.get(node_id) {
      Some(node) => {
        node.status = Compacted
        self.nodes.set(node_id, node)
      }
      None => ()
    }
  }

  self.compact_spans.push(CompactSpan::{
    start_node_id,
    end_node_id,
    summary_node_id: summary_id,
    hidden_node_ids,
  })

  self.head_id = current_head_id

  Some(summary_id)
}

///|
fn ChatTree::insert(
  self : Self,
  parent_id : NodeId?,
  spec : NodeInsert,
) -> NodeId {
  match parent_id {
    Some(parent_id) => {
      guard self.nodes.contains(parent_id) else { panic() }
    }
    None => ()
  }

  let node_id = self.alloc_node_id()
  let node = ChatNode::{
    id: node_id,
    parent_id,
    child_ids: [],
    message: spec.message,
    author_type: spec.author_type,
    op: spec.op,
    origin_node_id: spec.origin_node_id,
    status: spec.status,
    metadata: spec.metadata.copy(),
  }
  self.nodes.set(node_id, node)

  match parent_id {
    Some(parent_id) => {
      let parent = self.nodes.get(parent_id).unwrap()
      parent.child_ids.push(node_id)
      self.nodes.set(parent_id, parent)
    }
    None => if self.root_id is None { self.root_id = Some(node_id) }
  }

  self.head_id = Some(node_id)
  node_id
}

///|
fn ChatTree::alloc_node_id(self : Self) -> NodeId {
  let next = self.next_id
  self.next_id += 1
  "node-\{next}"
}

///|
fn ChatTree::path_nodes(self : Self, node_id : NodeId) -> Array[ChatNode] {
  let mut current = self.nodes.get(node_id)
  let nodes : Array[ChatNode] = []
  while current is Some(node) {
    nodes.push(clone_node(node))
    current = node.parent_id.bind(id => self.nodes.get(id))
  }
  nodes.rev_in_place()
  nodes
}

///|
fn ChatTree::context_nodes(self : Self, head_id : NodeId) -> Array[ChatNode] {
  let path = self.path_nodes(head_id)
  guard path.length() > 0 else { [] }

  let context : Array[ChatNode] = []
  let mut index = 0
  while index < path.length() {
    let node = path[index]
    if node.status is Hidden {
      index += 1
      continue
    }

    match self.summary_for_start(node.id, head_id) {
      Some(span) =>
        match self.nodes.get(span.summary_node_id) {
          Some(summary_node) => {
            context.push(clone_node(summary_node))
            index += span.hidden_node_ids.length()
          }
          None => {
            if !(node.status is Compacted) {
              context.push(clone_node(node))
            }
            index += 1
          }
        }
      None => {
        if !(node.status is Compacted) {
          context.push(clone_node(node))
        }
        index += 1
      }
    }
  }

  context
}

///|
fn ChatTree::summary_for_start(
  self : Self,
  start_node_id : NodeId,
  head_id : NodeId,
) -> CompactSpan? {
  let head_path = self.path_to(head_id)
  for span in self.compact_spans {
    if span.start_node_id == start_node_id &&
      head_path.contains(span.end_node_id) {
      return Some(clone_compact_span(span))
    }
  }
  None
}

///|
fn ChatTree::path_between(
  self : Self,
  start_node_id : NodeId,
  end_node_id : NodeId,
) -> Array[NodeId] {
  let end_path = self.path_to(end_node_id)
  match end_path.search(start_node_id) {
    Some(start_index) => {
      let path : Array[NodeId] = []
      for i in start_index..<end_path.length() {
        path.push(end_path[i])
      }
      path
    }
    None => []
  }
}

///|
fn default_author_type(role : Role) -> AuthorType {
  match role {
    System => SystemAuthor
    User => Human
    Assistant => Model
  }
}

///|
fn node_to_message(node : ChatNode) -> Message {
  node.message
}

///|
fn clone_node(node : ChatNode) -> ChatNode {
  ChatNode::{
    id: node.id,
    parent_id: node.parent_id,
    child_ids: node.child_ids.copy(),
    message: node.message,
    author_type: node.author_type,
    op: node.op,
    origin_node_id: node.origin_node_id,
    status: node.status,
    metadata: node.metadata.copy(),
  }
}

///|
fn clone_compact_span(span : CompactSpan) -> CompactSpan {
  CompactSpan::{
    start_node_id: span.start_node_id,
    end_node_id: span.end_node_id,
    summary_node_id: span.summary_node_id,
    hidden_node_ids: span.hidden_node_ids.copy(),
  }
}

///|
fn collect_nodes(nodes : Map[NodeId, ChatNode]) -> Array[ChatNode] {
  let entries = nodes.to_array()
  entries.sort_by((left, right) => String::compare(left.0, right.0))
  entries.map(entry => clone_node(entry.1))
}
