///|
pub struct ChatView {
  root : QWidget
  scroll : QScrollArea
  content : QWidget
  list : QBoxLayout
  mut rows : Array[QWidget]
  mut body_labels : Array[QLabel]
  mut node_ids : Array[String]
}

///|
let chat_view_style : String =
  #|QWidget#ChatView,
  #|QWidget#ChatViewContent,
  #|QWidget#MessageRow,
  #|QWidget#EmptyStateRow {
  #|  background: #f6f8fb;
  #|}
  #|
  #|QScrollArea#ChatScrollArea {
  #|  background: transparent;
  #|  border: none;
  #|}
  #|
  #|QWidget#SystemMessageCard,
  #|QWidget#UserMessageCard,
  #|QWidget#AssistantMessageCard {
  #|  border-radius: 16px;
  #|}
  #|
  #|QWidget#SystemMessageCard {
  #|  background: #f5f3ff;
  #|  border: 1px solid #ddd6fe;
  #|}
  #|
  #|QWidget#UserMessageCard {
  #|  background: #eef6ff;
  #|  border: 1px solid #bfdbfe;
  #|}
  #|
  #|QWidget#AssistantMessageCard {
  #|  background: #f8fafc;
  #|  border: 1px solid #dbe2ea;
  #|}
  #|
  #|QLabel#MessageRole {
  #|  background: transparent;
  #|  color: #667085;
  #|  font-size: 11px;
  #|  font-weight: 700;
  #|}
  #|
  #|QLabel#MessageMeta {
  #|  background: transparent;
  #|  color: #667085;
  #|  font-size: 11px;
  #|}
  #|
  #|QLabel#MessageBody {
  #|  background: transparent;
  #|  color: #101828;
  #|  font-size: 13px;
  #|}
  #|
  #|QLabel#EmptyState {
  #|  background: #f8fafc;
  #|  color: #667085;
  #|  border: 1px dashed #d0d5dd;
  #|  border-radius: 16px;
  #|  padding: 20px 24px;
  #|}

///|
pub fn ChatView::new() -> Self {
  try! ({
    let list = QBoxLayout::vertical()
    list.setContentsMargins(20, 16, 20, 16)
    list.setSpacing(12)
    list.addStretch(stretch=1)

    let content = QWidget::new()
    content.setObjectName("ChatViewContent")
    content.setLayout(list)

    let scroll = QScrollArea::new()
    scroll.setObjectName("ChatScrollArea")
    scroll.setFrameShape(NoFrame)
    scroll.setWidgetResizable(true)
    scroll.setHorizontalScrollBarPolicy(AlwaysOff)
    scroll.setWidget(content)

    let layout = QBoxLayout::vertical()
    layout.setContentsMargins(0, 0, 0, 0)
    layout.addWidget(scroll)

    let root = QWidget::new()
    root.setObjectName("ChatView")
    root.setLayout(layout)
    root.setStyleSheet(chat_view_style)

    let view = ChatView::{
      root,
      scroll,
      content,
      list,
      rows: [],
      body_labels: [],
      node_ids: [],
    }
    view
  })
}

///|
pub fn ChatView::set_messages(
  self : Self,
  tree : ChatTree,
  node_ids : Array[String],
) -> Unit raise NullptrError {
  self.clear_rows()

  if node_ids.length() == 0 {
    self.push_empty_row(build_empty_state())
  } else {
    for i in 0..<node_ids.length() {
      let node_id = node_ids[i]
      match tree.get_node(node_id) {
        Some(node) => {
          let content = tree.node_display_content(node_id).unwrap_or("")
          let (row, body) = build_message_row_from_node(node, content, i)
          self.push_row(row, body)
        }
        None => ()
      }
    }
  }

  self.node_ids = node_ids.copy()

  self.scroll_to_bottom()
}

///|
pub fn ChatView::update_streaming_message(
  self : Self,
  node_id : String,
  content : String,
) -> Unit raise NullptrError {
  let index = find_node_index(self.node_ids, node_id)
  match index {
    Some(i) if i >= 0 && i < self.body_labels.length() => {
      self.body_labels[i].setText(content)
      self.scroll_to_bottom()
    }
    _ => ()
  }
}

///|
fn ChatView::scroll_to_bottom(self : Self) -> Unit raise NullptrError {
  let scrollbar = self.scroll.verticalScrollBar()
  scrollbar.setValue(scrollbar.maximum())
}

///|
fn ChatView::push_row(
  self : Self,
  row : QWidget,
  body : QLabel,
) -> Unit raise NullptrError {
  self.list.insertWidget(self.list.count() - 1, row)
  self.rows.push(row)
  self.body_labels.push(body)
}

///|
fn ChatView::push_empty_row(
  self : Self,
  row : QWidget,
) -> Unit raise NullptrError {
  self.list.insertWidget(self.list.count() - 1, row, stretch=1)
  self.rows.push(row)
}

///|
fn ChatView::clear_rows(self : Self) -> Unit raise NullptrError {
  for row in self.rows {
    self.list.removeWidget(row)
    row.deleteLater()
  }
  self.rows = []
  self.body_labels = []
}

///|
fn find_node_index(node_ids : Array[String], target_id : String) -> Int? {
  for i in 0..<node_ids.length() {
    if node_ids[i] == target_id {
      return Some(i)
    }
  }
  None
}

///|
fn build_message_row_from_node(
  node : ChatNode,
  content : String,
  index : Int,
) -> (QWidget, QLabel) {
  try! ({
    let role = role_text(node.message.role)

    let header = QBoxLayout::horizontal()
    header.setContentsMargins(0, 0, 0, 0)
    header.setSpacing(8)

    let role_label = QLabel::new()
    role_label.setObjectName("MessageRole")
    role_label.setText(role)

    let index_label = QLabel::new()
    index_label.setObjectName("MessageMeta")
    index_label.setText("#\{index + 1}")

    header.addWidget(role_label)
    header.addStretch(stretch=1)
    header.addWidget(index_label)

    let body = QLabel::new()
    body.setObjectName("MessageBody")
    body.setTextFormat(Plain)
    body.setWordWrap(true)
    body.setText(content)

    let card_layout = QBoxLayout::vertical()
    card_layout.setContentsMargins(14, 12, 14, 12)
    card_layout.setSpacing(8)
    card_layout.addLayout(header)
    card_layout.addWidget(body)

    let card = QWidget::new()
    card.setObjectName(role_card_name(node.message.role))
    card.setMaximumWidth(720)
    card.setLayout(card_layout)

    let row_layout = QBoxLayout::horizontal()
    row_layout.setContentsMargins(0, 0, 0, 0)
    row_layout.setSpacing(12)

    if node.message.role is User {
      row_layout.addStretch(stretch=1)
      row_layout.addWidget(card)
    } else {
      row_layout.addWidget(card)
      row_layout.addStretch(stretch=1)
    }

    let row = QWidget::new()
    row.setObjectName("MessageRow")
    row.setLayout(row_layout)
    (row, body)
  })
}

///|
fn build_empty_state() -> QWidget {
  try! ({
    let label = QLabel::new()
    label.setObjectName("EmptyState")
    label.setWordWrap(true)
    label.setText(
      "还没有消息。\n从下方输入框开始一段新对话吧。",
    )

    let middle = QBoxLayout::horizontal()
    middle.setContentsMargins(0, 0, 0, 0)
    middle.addStretch(stretch=1)
    middle.addWidget(label)
    middle.addStretch(stretch=1)

    let layout = QBoxLayout::vertical()
    layout.setContentsMargins(0, 0, 0, 0)
    layout.addStretch(stretch=1)
    layout.addLayout(middle)
    layout.addStretch(stretch=1)

    let row = QWidget::new()
    row.setObjectName("EmptyStateRow")
    row.setLayout(layout)
    row
  })
}

///|
fn role_text(role : Role) -> String {
  match role {
    System => "SYSTEM"
    User => "USER"
    Assistant => "ASSISTANT"
  }
}

///|
fn role_card_name(role : Role) -> String {
  match role {
    System => "SystemMessageCard"
    User => "UserMessageCard"
    Assistant => "AssistantMessageCard"
  }
}

///|
pub impl AsObject for ChatView with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ChatView with as_widget(self) {
  self.root.as_widget()
}
