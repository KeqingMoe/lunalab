///|
pub(all) struct SnapshotModel {
  node_count : Int
  root_id : Int?
  head_id : Int?
} derive(Eq, Debug)

///|
pub(all) enum PathModel {
  RootPath(Int)
  ChildPath(PathModel, Int)
} derive(Eq, Debug)

///|
pub(all) enum HistoryModel {
  RootHistory(Int)
  HistoryAppend(HistoryModel, Int)
} derive(Eq, Debug)

///|
#proof_pure
pub fn contains_node(model : SnapshotModel, node_id : Int) -> Bool {
  node_id >= 0 && node_id < model.node_count
}

///|
#proof_pure
pub fn node_count_valid(model : SnapshotModel) -> Bool {
  model.node_count >= 0
}

///|
#proof_pure
pub fn root_member(model : SnapshotModel) -> Bool {
  match model.root_id {
    None => true
    Some(root) => contains_node(model, root)
  }
}

///|
#proof_pure
pub fn head_member(model : SnapshotModel) -> Bool {
  match model.head_id {
    None => true
    Some(head) => contains_node(model, head)
  }
}

///|
pub fn is_well_formed(
  model : SnapshotModel,
) -> Bool where {
  proof_ensure:
    result =>
      result ==
      (node_count_valid(model) && root_member(model) && head_member(model)),
} {
  node_count_valid(model) && root_member(model) && head_member(model)
}

///|
#proof_pure
pub fn root_path(root : Int) -> PathModel {
  RootPath(root)
}

///|
#proof_pure
pub fn append_child(path : PathModel, child : Int) -> PathModel {
  ChildPath(path, child)
}

///|
#proof_pure
pub fn root_history(root : Int) -> HistoryModel {
  RootHistory(root)
}

///|
#proof_pure
pub fn append_history(history : HistoryModel, node_id : Int) -> HistoryModel {
  HistoryAppend(history, node_id)
}

///|
#proof_pure
pub fn fresh_node_id(model : SnapshotModel) -> Int {
  model.node_count
}

///|
#proof_pure
pub fn commit_model(model : SnapshotModel) -> SnapshotModel {
  let fresh = fresh_node_id(model)
  SnapshotModel::{
    node_count: model.node_count + 1,
    root_id:
      match model.root_id {
        None => Some(fresh)
        Some(root) => Some(root)
      },
    head_id: Some(fresh),
  }
}
