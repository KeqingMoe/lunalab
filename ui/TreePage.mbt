///|
using @core {type ChatNode, type NodeId}

///|
priv struct TreeLayoutNode {
  id : NodeId
  x : Double
  y : Double
}

///|
struct TreeRenderedNode {
  id : NodeId
  card : QWidget
  select : QPushButton
}

///|
pub struct TreePage {
  root : QWidget
  mut tree : ChatTree
  scene : QGraphicsScene
  view : QGraphicsView
  selected_status : QLabel
  head_status : QLabel
  move_head : QPushButton
  zoom_in : QPushButton
  zoom_out : QPushButton
  fit_view_btn : QPushButton
  changed_notifier : QPushButton
  mut selected_id : NodeId?
  mut rendered_nodes : Array[TreeRenderedNode]
}

///|
let tree_page_style : String =
  #|QWidget#TreePage {
  #|  background: #f2f5fa;
  #|}
  #|
  #|QWidget#TreeCanvasCard {
  #|  background: #f7f9fc;
  #|  border: 1px solid #e5ebf2;
  #|  border-radius: 24px;
  #|}
  #|
  #|QWidget#TreeCanvasToolbarShell,
  #|QWidget#TreeStatusGroup,
  #|QWidget#TreeZoomGroup {
  #|  background: transparent;
  #|  border: none;
  #|}
  #|
  #|QWidget#TreeCanvasToolbar {
  #|  background: #ffffff;
  #|  border: 1px solid #e2e8f0;
  #|  border-radius: 18px;
  #|}
  #|
  #|QWidget#TreeToolbarDivider {
  #|  background: #e4e7ec;
  #|}
  #|
  #|QLabel#TreeSelectedStatus,
  #|QLabel#TreeHeadStatus {
  #|  border-radius: 13px;
  #|  padding: 4px 10px;
  #|  font-size: 11px;
  #|  font-weight: 800;
  #|}
  #|
  #|QLabel#TreeSelectedStatus {
  #|  background: #eef4ff;
  #|  color: #175cd3;
  #|  border: 1px solid #c7d7fe;
  #|}
  #|
  #|QLabel#TreeHeadStatus {
  #|  background: #ecfdf3;
  #|  color: #027a48;
  #|  border: 1px solid #b7ebc6;
  #|}
  #|
  #|QPushButton#TreePrimaryButton,
  #|QPushButton#TreeActionButton,
  #|QPushButton#TreeNodeSelectButton {
  #|  font-size: 12px;
  #|  font-weight: 700;
  #|}
  #|
  #|QPushButton#TreePrimaryButton {
  #|  background: #101828;
  #|  color: #ffffff;
  #|  border: 1px solid #101828;
  #|  border-radius: 14px;
  #|  padding: 0 12px;
  #|}
  #|
  #|QPushButton#TreePrimaryButton:hover {
  #|  background: #1d2939;
  #|  border-color: #1d2939;
  #|}
  #|
  #|QPushButton#TreePrimaryButton:pressed {
  #|  background: #344054;
  #|  border-color: #344054;
  #|}
  #|
  #|QPushButton#TreePrimaryButton:disabled {
  #|  background: #f2f4f7;
  #|  color: #98a2b3;
  #|  border-color: #e4e7ec;
  #|}
  #|
  #|QPushButton#TreeActionButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border: 1px solid #d7dde6;
  #|  border-radius: 12px;
  #|  padding: 0 10px;
  #|}
  #|
  #|QPushButton#TreeActionButton:hover {
  #|  background: #f8fafc;
  #|  border-color: #c7d2de;
  #|}
  #|
  #|QPushButton#TreeActionButton:pressed {
  #|  background: #eef2f6;
  #|  border-color: #c7d2de;
  #|}
  #|
  #|QGraphicsView#TreeCanvas {
  #|  background: #fcfdff;
  #|  border: 1px solid #ebeff5;
  #|  border-radius: 20px;
  #|}
  #|
  #|QLabel#TreeEmptyState {
  #|  background: #ffffff;
  #|  color: #667085;
  #|  border: 1px dashed #d0dbe8;
  #|  border-radius: 18px;
  #|  padding: 18px 22px;
  #|  font-size: 13px;
  #|  font-weight: 700;
  #|}

///|
let tree_node_width = 220.0

///|
let tree_node_height = 132.0

///|
let tree_leaf_span = 252.0

///|
let tree_sibling_gap = 56.0

///|
let tree_vertical_gap = 172.0

///|
let tree_top_padding = 36.0

///|
let tree_fit_focus_padding_x = 96.0

///|
let tree_fit_focus_padding_y = 88.0

///|
let tree_fit_single_padding_x = 132.0

///|
let tree_fit_single_padding_y = 116.0

///|
let tree_fit_min_scale = 0.76

///|
pub fn TreePage::new() -> Self {
  try! ({
    let tree = new_chat_tree()

    let selected_status = QLabel::new()
    selected_status.setObjectName("TreeSelectedStatus")
    selected_status.setFixedHeight(30)

    let head_status = QLabel::new()
    head_status.setObjectName("TreeHeadStatus")
    head_status.setFixedHeight(30)

    let status_layout = QBoxLayout::horizontal()
    status_layout.setContentsMargins(0, 0, 0, 0)
    status_layout.setSpacing(6)
    status_layout.addWidget(selected_status)
    status_layout.addWidget(head_status)

    let status_group = QWidget::new()
    status_group.setObjectName("TreeStatusGroup")
    status_group.setLayout(status_layout)

    let move_head = QPushButton::new()
    move_head.setObjectName("TreePrimaryButton")
    move_head.setText("把 HEAD 移到选中节点")
    move_head.setFixedHeight(32)

    let zoom_out = QPushButton::new()
    zoom_out.setObjectName("TreeActionButton")
    zoom_out.setText("缩小")
    zoom_out.setFixedHeight(30)

    let zoom_in = QPushButton::new()
    zoom_in.setObjectName("TreeActionButton")
    zoom_in.setText("放大")
    zoom_in.setFixedHeight(30)

    let fit_view_btn = QPushButton::new()
    fit_view_btn.setObjectName("TreeActionButton")
    fit_view_btn.setText("适配")
    fit_view_btn.setFixedHeight(30)

    let zoom_layout = QBoxLayout::horizontal()
    zoom_layout.setContentsMargins(0, 0, 0, 0)
    zoom_layout.setSpacing(6)
    zoom_layout.addWidget(zoom_out)
    zoom_layout.addWidget(zoom_in)
    zoom_layout.addWidget(fit_view_btn)

    let zoom_group = QWidget::new()
    zoom_group.setObjectName("TreeZoomGroup")
    zoom_group.setLayout(zoom_layout)

    let divider_a = QWidget::new()
    divider_a.setObjectName("TreeToolbarDivider")
    divider_a.setMinimumWidth(1)
    divider_a.setMaximumWidth(1)
    divider_a.setFixedHeight(18)

    let divider_b = QWidget::new()
    divider_b.setObjectName("TreeToolbarDivider")
    divider_b.setMinimumWidth(1)
    divider_b.setMaximumWidth(1)
    divider_b.setFixedHeight(18)

    let toolbar_layout = QBoxLayout::horizontal()
    toolbar_layout.setContentsMargins(10, 10, 10, 10)
    toolbar_layout.setSpacing(10)
    toolbar_layout.addWidget(status_group)
    toolbar_layout.addWidget(divider_a)
    toolbar_layout.addWidget(move_head)
    toolbar_layout.addWidget(divider_b)
    toolbar_layout.addWidget(zoom_group)

    let toolbar = QWidget::new()
    toolbar.setObjectName("TreeCanvasToolbar")
    toolbar.setLayout(toolbar_layout)

    let toolbar_shell_layout = QBoxLayout::horizontal()
    toolbar_shell_layout.setContentsMargins(0, 0, 0, 0)
    toolbar_shell_layout.setSpacing(0)
    toolbar_shell_layout.addWidget(toolbar)
    toolbar_shell_layout.addStretch(stretch=1)

    let toolbar_shell = QWidget::new()
    toolbar_shell.setObjectName("TreeCanvasToolbarShell")
    toolbar_shell.setLayout(toolbar_shell_layout)

    let scene = QGraphicsScene::new()
    let view = QGraphicsView::new()
    view.setObjectName("TreeCanvas")
    view.setScene(scene)
    view.setRenderHint(Antialiasing)
    view.setRenderHint(TextAntialiasing)
    view.setRenderHint(SmoothPixmapTransform)
    view.setDragMode(ScrollHandDrag)
    view.setViewportUpdateMode(BoundingRectViewportUpdate)
    view.setTransformationAnchor(AnchorUnderMouse)
    view.setResizeAnchor(AnchorViewCenter)
    view.setFrameShape(NoFrame)
    view.setHorizontalScrollBarPolicy(AlwaysOff)
    view.setVerticalScrollBarPolicy(AlwaysOff)

    let canvas_layout = QBoxLayout::vertical()
    canvas_layout.setContentsMargins(14, 14, 14, 14)
    canvas_layout.setSpacing(12)
    canvas_layout.addWidget(toolbar_shell)
    canvas_layout.addWidget(view, stretch=1)

    let canvas = QWidget::new()
    canvas.setObjectName("TreeCanvasCard")
    canvas.setLayout(canvas_layout)
    canvas.setSizePolicy(QSizePolicy::new(Expanding, Preferred))

    let content = QBoxLayout::horizontal()
    content.setContentsMargins(14, 14, 14, 14)
    content.setSpacing(0)
    content.addWidget(canvas, stretch=1)

    let root = QWidget::new()
    root.setObjectName("TreePage")
    root.setStyleSheet(tree_page_style)
    root.setLayout(content)

    scene.setParent(root)

    let changed_notifier = QPushButton::new()
    changed_notifier.setParent(root)
    changed_notifier.setVisible(false)

    let page = TreePage::{
      root,
      tree,
      scene,
      view,
      selected_status,
      head_status,
      move_head,
      zoom_in,
      zoom_out,
      fit_view_btn,
      changed_notifier,
      selected_id: None,
      rendered_nodes: [],
    }

    let _ = page.move_head.clicked().connect(_ => page.move_head_to_selected())
    let _ = page.zoom_in.clicked().connect(_ => page.view.scale(1.14, 1.14))
    let _ = page.zoom_out.clicked().connect(_ => page.view.scale(0.88, 0.88))
    let _ = page.fit_view_btn.clicked().connect(_ => page.fit_view())

    page.sync_panel()
    page.render_tree(refit=true)
    page
  })
}

///|
pub fn TreePage::load_tree(
  self : Self,
  tree : ChatTree,
) -> Unit raise NullptrError {
  self.tree = tree
  self.selected_id = preferred_selected_id(self.tree, self.selected_id)
  self.sync_panel()
  self.render_tree(refit=true)
}

///|
pub fn TreePage::tree_changed(self : Self) -> Signal[Bool] raise NullptrError {
  self.changed_notifier.clicked()
}

///|
pub fn TreePage::tree(self : Self) -> ChatTree {
  self.tree
}

///|
fn TreePage::move_head_to_selected(self : Self) -> Unit raise NullptrError {
  guard self.selected_id is Some(selected_id) else { () }
  guard self.tree.move_head(selected_id) else { () }
  self.sync_panel()
  self.render_tree(refit=true)
  self.changed_notifier.click()
}

///|
fn TreePage::select_node(
  self : Self,
  node_id : NodeId,
) -> Unit raise NullptrError {
  guard self.selected_id != Some(node_id) else { () }
  self.selected_id = Some(node_id)
  self.sync_panel()
  self.sync_node_visuals()
}

///|
fn TreePage::sync_panel(self : Self) -> Unit raise NullptrError {
  let selected_text = match self.selected_id {
    Some(node_id) => "Selected " + node_id
    None => "Selected --"
  }
  let head_id = self.tree.head_id()
  let head_text = match head_id {
    Some(node_id) => "HEAD " + node_id
    None => "HEAD --"
  }

  self.selected_status.setText(selected_text)
  self.head_status.setText(head_text)
  self.move_head.setEnabled(
    match self.selected_id {
      Some(selected_id) => head_id != Some(selected_id)
      None => false
    },
  )
}

///|
fn TreePage::render_tree(
  self : Self,
  refit? : Bool = false,
) -> Unit raise NullptrError {
  self.rendered_nodes = []
  self.scene.clear()
  guard self.tree.root_id() is Some(root_id) else {
    self.render_empty_state()
    if refit {
      self.fit_view()
    }
    ()
  }

  let layout_nodes = build_tree_layout(self.tree, root_id)
  let head_path = match self.tree.head_id() {
    Some(head_id) => self.tree.path_to(head_id)
    None => []
  }

  for layout in layout_nodes {
    match self.tree.get_node(layout.id) {
      Some(node) =>
        match node.parent_id {
          Some(parent_id) =>
            match layout_node_by_id(layout_nodes, parent_id) {
              Some(parent_layout) =>
                ignore(
                  self.render_edge(
                    parent_layout,
                    layout,
                    head_path.contains(layout.id),
                  ),
                )
              None => ()
            }
          None => ()
        }
      None => ()
    }
  }

  for layout in layout_nodes {
    match self.tree.get_node(layout.id) {
      Some(node) => ignore(self.render_node(layout, node))
      None => ()
    }
  }

  let bounds = self.scene.itemsBoundingRect()
  let padded = if bounds.isEmpty() {
    QRectF::new(-240.0, -140.0, 480.0, 280.0)
  } else {
    bounds.adjusted(-120.0, -96.0, 120.0, 108.0)
  }
  self.scene.setSceneRect(padded)
  self.view.setSceneRect(padded)

  if refit {
    self.fit_view()
  }
  self.sync_node_visuals()
}

///|
fn TreePage::render_empty_state(self : Self) -> Unit raise NullptrError {
  let label = QLabel::new()
  label.setObjectName("TreeEmptyState")
  label.setAlignment(Alignment::center())
  label.setWordWrap(true)
  label.setText(
    "画布还是空的。\n去 Chat 发第一条消息，结构会在这里长出来。",
  )
  let proxy = self.scene.addWidget(label)
  proxy.setPos(-156.0, -42.0)
  let rect = QRectF::new(-240.0, -140.0, 480.0, 280.0)
  self.scene.setSceneRect(rect)
  self.view.setSceneRect(rect)
}

///|
fn TreePage::render_edge(
  self : Self,
  parent : TreeLayoutNode,
  child : TreeLayoutNode,
  highlighted : Bool,
) -> QGraphicsPathItem raise NullptrError {
  let start = QPointF::new(parent.x, parent.y + tree_node_height / 2.0 - 6.0)
  let end = QPointF::new(child.x, child.y - tree_node_height / 2.0 + 6.0)
  let mid_y = (start.y() + end.y()) / 2.0

  let path = QPainterPath::new()
  path.moveTo(start)
  path.cubicTo(
    QPointF::new(start.x(), mid_y),
    QPointF::new(end.x(), mid_y),
    end,
  )

  let pen = QPen::newWithColor(
    if highlighted {
      QColor::newWithName("#2f9e6f")
    } else {
      QColor::newWithName("#d7e0ea")
    },
  )
  pen.setWidthF(if highlighted { 2.6 } else { 1.6 })
  pen.setStyle(SolidLine)
  pen.setCapStyle(RoundCap)
  pen.setJoinStyle(RoundJoin)

  let item = self.scene.addPath(path, pen)
  item.setZValue(1.0)
  item
}

///|
fn TreePage::render_node(
  self : Self,
  layout : TreeLayoutNode,
  node : ChatNode,
) -> QGraphicsProxyWidget raise NullptrError {
  let accent = QWidget::new()
  accent.setObjectName("TreeNodeAccent")
  accent.setFixedHeight(4)

  let role = QLabel::new()
  role.setObjectName("TreeNodeRoleBadge")
  role.setText(node_role_text(node))

  let node_id = QLabel::new()
  node_id.setObjectName("TreeNodeId")
  node_id.setText(node.id)

  let header = QBoxLayout::horizontal()
  header.setContentsMargins(0, 0, 0, 0)
  header.setSpacing(8)
  header.addWidget(role)
  header.addStretch(stretch=1)
  header.addWidget(node_id)

  let preview = QLabel::new()
  preview.setObjectName("TreeNodePreview")
  preview.setWordWrap(true)
  preview.setText(node_preview_text(node.message.content))

  let meta = QLabel::new()
  meta.setObjectName("TreeNodeMeta")
  meta.setText(node_meta_text(node))

  let select = QPushButton::new()
  select.setObjectName("TreeNodeSelectButton")
  select.setText("查看")
  select.setFixedHeight(26)

  let footer = QBoxLayout::horizontal()
  footer.setContentsMargins(0, 0, 0, 0)
  footer.setSpacing(8)
  footer.addWidget(meta)
  footer.addStretch(stretch=1)
  footer.addWidget(select)

  let body = QBoxLayout::vertical()
  body.setContentsMargins(12, 12, 12, 12)
  body.setSpacing(8)
  body.addLayout(header)
  body.addWidget(preview)
  body.addStretch(stretch=1)
  body.addLayout(footer)

  let content = QBoxLayout::vertical()
  content.setContentsMargins(0, 0, 0, 0)
  content.setSpacing(0)
  content.addWidget(accent)
  content.addLayout(body)

  let card = QWidget::new()
  card.setObjectName("TreeNodeCard")
  card.setLayout(content)
  card.setFixedWidth(tree_node_width.to_int())
  card.setFixedHeight(tree_node_height.to_int())

  let proxy = self.scene.addWidget(card)
  proxy.setPos(
    layout.x - tree_node_width / 2.0,
    layout.y - tree_node_height / 2.0,
  )
  proxy.setZValue(4.0)

  let node_id_value = node.id
  let _ = select.clicked().connect(_ => self.select_node(node_id_value))
  self.rendered_nodes.push(TreeRenderedNode::{ id: node.id, card, select })
  proxy
}

///|
fn TreePage::sync_node_visuals(self : Self) -> Unit raise NullptrError {
  let head_id = self.tree.head_id()
  for rendered in self.rendered_nodes {
    let is_head = head_id == Some(rendered.id)
    let is_selected = self.selected_id == Some(rendered.id)
    match self.tree.get_node(rendered.id) {
      Some(node) =>
        rendered.card.setStyleSheet(
          tree_node_card_style(node, is_head, is_selected),
        )
      None => ()
    }
    rendered.select.setText(if is_selected { "已选中" } else { "查看" })
    rendered.select.setEnabled(!is_selected)
  }
}

///|
fn TreePage::fit_view(self : Self) -> Unit raise NullptrError {
  let padded = self.fit_target_rect()
  self.view.resetTransform()
  self.view.fitInView(padded, mode=Keep)
  let width_ratio = self.view.width().to_double() / padded.width().max(1.0)
  let height_ratio = self.view.height().to_double() / padded.height().max(1.0)
  let fitted_scale = width_ratio.min(height_ratio)
  if fitted_scale < tree_fit_min_scale {
    self.view.resetTransform()
    self.view.scale(tree_fit_min_scale, tree_fit_min_scale)
    self.view.centerOn(fit_target_center(padded))
  }
}

///|
fn TreePage::fit_target_rect(self : Self) -> QRectF raise NullptrError {
  let bounds = self.scene.itemsBoundingRect()
  guard self.tree.root_id() is Some(root_id) else {
    if bounds.isEmpty() {
      return QRectF::new(-240.0, -140.0, 480.0, 280.0)
    }
    return bounds.adjusted(-96.0, -88.0, 96.0, 88.0)
  }

  let layout_nodes = build_tree_layout(self.tree, root_id)
  guard layout_nodes.length() > 0 else {
    if bounds.isEmpty() {
      return QRectF::new(-240.0, -140.0, 480.0, 280.0)
    }
    return bounds.adjusted(-96.0, -88.0, 96.0, 88.0)
  }

  let focus_id = preferred_fit_focus_id(self.tree, self.selected_id)
  let focus_ids = collect_fit_focus_ids(self.tree, focus_id)
  let focus_rect = focus_rect_from_layout(layout_nodes, focus_ids)
  guard focus_rect is Some(rect) else {
    if bounds.isEmpty() {
      return QRectF::new(-240.0, -140.0, 480.0, 280.0)
    }
    return bounds.adjusted(-96.0, -88.0, 96.0, 88.0)
  }

  let padded = if focus_ids.length() <= 1 {
    rect.adjusted(
      -tree_fit_single_padding_x,
      -tree_fit_single_padding_y,
      tree_fit_single_padding_x,
      tree_fit_single_padding_y,
    )
  } else {
    rect.adjusted(
      -tree_fit_focus_padding_x,
      -tree_fit_focus_padding_y,
      tree_fit_focus_padding_x,
      tree_fit_focus_padding_y,
    )
  }

  if bounds.isEmpty() {
    padded
  } else {
    padded.intersected(bounds.adjusted(-12.0, -12.0, 12.0, 12.0))
  }
}

///|
fn fit_target_center(rect : QRectF) -> QPointF {
  QPointF::new(rect.x() + rect.width() / 2.0, rect.y() + rect.height() / 2.0)
}

///|
fn preferred_fit_focus_id(tree : ChatTree, selected_id : NodeId?) -> NodeId? {
  match selected_id {
    Some(node_id) if tree.get_node(node_id) is Some(_) => Some(node_id)
    _ =>
      match tree.head_id() {
        Some(head_id) => Some(head_id)
        None => tree.root_id()
      }
  }
}

///|
fn collect_fit_focus_ids(tree : ChatTree, focus_id : NodeId?) -> Array[NodeId] {
  guard focus_id is Some(focus_id) else { [] }
  let ids : Array[NodeId] = []
  push_unique_id(ids, focus_id)

  match tree.get_node(focus_id) {
    Some(focus_node) => {
      match focus_node.parent_id {
        Some(parent_id) => {
          push_unique_id(ids, parent_id)
          for sibling in tree.get_children(parent_id) {
            push_unique_id(ids, sibling.id)
          }
        }
        None => ()
      }

      for child in tree.get_children(focus_id) {
        push_unique_id(ids, child.id)
      }
    }
    None => ()
  }

  ids
}

///|
fn push_unique_id(ids : Array[NodeId], node_id : NodeId) -> Unit {
  if !ids.contains(node_id) {
    ids.push(node_id)
  }
}

///|
fn focus_rect_from_layout(
  layout_nodes : Array[TreeLayoutNode],
  focus_ids : Array[NodeId],
) -> QRectF? {
  let mut rect : QRectF? = None
  for node_id in focus_ids {
    match layout_node_by_id(layout_nodes, node_id) {
      Some(layout) => {
        let node_rect = QRectF::new(
          layout.x - tree_node_width / 2.0,
          layout.y - tree_node_height / 2.0,
          tree_node_width,
          tree_node_height,
        )
        rect = Some(
          match rect {
            Some(current) => current.united(node_rect)
            None => node_rect
          },
        )
      }
      None => ()
    }
  }
  rect
}

///|
fn preferred_selected_id(tree : ChatTree, current : NodeId?) -> NodeId? {
  match current {
    Some(id) if tree.get_node(id) is Some(_) => Some(id)
    _ =>
      match tree.head_id() {
        Some(head_id) => Some(head_id)
        None => tree.root_id()
      }
  }
}

///|
fn build_tree_layout(
  tree : ChatTree,
  root_id : NodeId,
) -> Array[TreeLayoutNode] {
  let nodes = []
  ignore(layout_subtree(tree, root_id, 0, 0.0, nodes))
  nodes
}

///|
fn layout_subtree(
  tree : ChatTree,
  node_id : NodeId,
  depth : Int,
  left : Double,
  into : Array[TreeLayoutNode],
) -> Double {
  let span = subtree_span(tree, node_id)
  into.push(TreeLayoutNode::{
    id: node_id,
    x: left + span / 2.0,
    y: tree_top_padding + depth.to_double() * tree_vertical_gap,
  })

  let children = tree.get_children(node_id)
  let mut child_left = left
  for index in 0..<children.length() {
    let child = children[index]
    let child_span = layout_subtree(tree, child.id, depth + 1, child_left, into)
    child_left += child_span
    if index + 1 < children.length() {
      child_left += tree_sibling_gap
    }
  }
  span
}

///|
fn subtree_span(tree : ChatTree, node_id : NodeId) -> Double {
  let children = tree.get_children(node_id)
  guard children.length() > 0 else { tree_leaf_span }

  let mut width = 0.0
  for index in 0..<children.length() {
    width += subtree_span(tree, children[index].id)
    if index + 1 < children.length() {
      width += tree_sibling_gap
    }
  }
  width.max(tree_leaf_span)
}

///|
fn layout_node_by_id(
  nodes : Array[TreeLayoutNode],
  target_id : NodeId,
) -> TreeLayoutNode? {
  for node in nodes {
    if node.id == target_id {
      return Some(node)
    }
  }
  None
}

///|
fn tree_node_card_style(
  node : ChatNode,
  is_head : Bool,
  is_selected : Bool,
) -> String {
  let (card_background, card_border) = if is_head && is_selected {
    ("#f8fbff", "#98b6ff")
  } else if is_head {
    ("#fbfffc", "#d6e8dc")
  } else if is_selected {
    ("#f8fbff", "#9db8ff")
  } else {
    ("#ffffff", "#dbe3ec")
  }
  let accent = if is_head {
    "#2f9e6f"
  } else if is_selected {
    "#7aa2ff"
  } else {
    "#eef2f6"
  }
  let (role_background, role_color) = match node.message.role {
    System => ("#f2f4f7", "#344054")
    User => ("#eef4ff", "#175cd3")
    Assistant => ("#fff7e8", "#b54708")
  }
  let id_color = if is_selected { "#667085" } else { "#98a2b3" }
  let meta_color = if is_head { "#027a48" } else { "#667085" }
  let button_background = if is_selected { "#eef4ff" } else { "#ffffff" }
  let button_border = if is_selected { "#c7d7fe" } else { "#d7dde6" }
  let button_color = if is_selected { "#175cd3" } else { "#667085" }
  let button_hover_background = if is_selected { "#eef4ff" } else { "#f8fafc" }

  "QWidget#TreeNodeCard { background: " +
  card_background +
  "; border: 1px solid " +
  card_border +
  "; border-radius: 18px; }" +
  "QWidget#TreeNodeAccent { background: " +
  accent +
  "; border: none; border-top-left-radius: 17px; border-top-right-radius: 17px; }" +
  "QLabel#TreeNodeRoleBadge { background: " +
  role_background +
  "; color: " +
  role_color +
  "; border: none; border-radius: 10px; padding: 2px 8px; font-size: 10px; font-weight: 800; }" +
  "QLabel#TreeNodeId { background: transparent; color: " +
  id_color +
  "; font-size: 11px; font-weight: 700; }" +
  "QLabel#TreeNodePreview { background: transparent; color: #101828; font-size: 14px; font-weight: 700; }" +
  "QLabel#TreeNodeMeta { background: transparent; color: " +
  meta_color +
  "; font-size: 11px; }" +
  "QPushButton#TreeNodeSelectButton { background: " +
  button_background +
  "; color: " +
  button_color +
  "; border: 1px solid " +
  button_border +
  "; border-radius: 10px; padding: 0 10px; font-size: 11px; font-weight: 700; }" +
  "QPushButton#TreeNodeSelectButton:hover { background: " +
  button_hover_background +
  "; }" +
  "QPushButton#TreeNodeSelectButton:disabled { background: #eef4ff; color: #175cd3; border-color: #c7d7fe; }"
}

///|
fn node_role_text(node : ChatNode) -> String {
  match node.message.role {
    System => "系统"
    User => "用户"
    Assistant => "助手"
  }
}

///|
fn node_meta_text(node : ChatNode) -> String {
  match node.parent_id {
    Some(parent_id) => "parent " + parent_id
    None => "root node"
  }
}

///|
fn node_preview_text(content : String) -> String {
  let title = normalize_conversation_title(content)
  if title.length() <= 44 {
    title
  } else {
    title[:44].to_string() + "..."
  }
}

///|
pub impl AsObject for TreePage with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for TreePage with as_widget(self) {
  self.root
}
