///|
pub struct LeftSidebar {
  root : QWidget
  count_label : QLabel
  new_chat : QPushButton
  list : QBoxLayout
  buttons : QButtonGroup
  mut rows : Array[QPushButton]
  mut interactions_enabled : Bool
}

///|
let sidebar_style : String =
  #|QWidget#LeftSidebar {
  #|  background: #fbfbfc;
  #|  border-right: 1px solid #eaecf0;
  #|}
  #|
  #|QLabel#SidebarHeading {
  #|  background: transparent;
  #|  color: #101828;
  #|  font-size: 18px;
  #|  font-weight: 800;
  #|}
  #|
  #|QLabel#SidebarCount {
  #|  background: transparent;
  #|  color: #98a2b3;
  #|  font-size: 12px;
  #|  font-weight: 600;
  #|}
  #|
  #|QPushButton#SidebarNewChatButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border: 1px solid #d7dde6;
  #|  border-radius: 10px;
  #|  padding: 0;
  #|  font-size: 16px;
  #|  font-weight: 700;
  #|  text-align: center;
  #|}
  #|
  #|QPushButton#SidebarNewChatButton:hover {
  #|  background: #f9fbff;
  #|  border-color: #c7d7fe;
  #|}
  #|
  #|QPushButton#SidebarNewChatButton:pressed {
  #|  background: #eef2f6;
  #|  border-color: #c7d7fe;
  #|}
  #|
  #|QScrollArea#SidebarScroll {
  #|  background: transparent;
  #|  border: none;
  #|}
  #|
  #|QWidget#SidebarScrollContent {
  #|  background: transparent;
  #|}
  #|
  #|QPushButton#SidebarConversationButton {
  #|  background: transparent;
  #|  color: #101828;
  #|  border: 1px solid transparent;
  #|  border-radius: 10px;
  #|  padding: 0 12px;
  #|  font-size: 14px;
  #|  font-weight: 600;
  #|  text-align: left;
  #|}
  #|
  #|QPushButton#SidebarConversationButton:hover {
  #|  background: #f2f4f7;
  #|}
  #|
  #|QPushButton#SidebarConversationButton:pressed {
  #|  background: #eaeef3;
  #|}
  #|
  #|QPushButton#SidebarConversationButton:checked {
  #|  background: #eef4ff;
  #|  border: 1px solid #cfe0ff;
  #|  color: #0f172a;
  #|}

///|
fn sidebar_min_width() -> Int {
  190
}

///|
fn sidebar_default_width() -> Int {
  240
}

///|
fn sidebar_max_width() -> Int {
  620
}

///|
fn sidebar_collapse_threshold() -> Int {
  24
}

///|
fn sidebar_title_preview(title : String) -> String {
  let trimmed = title.trim().to_string()
  guard trimmed != "" else { "新对话" }

  let max_chars = 26
  if trimmed.length() <= max_chars {
    trimmed
  } else {
    trimmed[:max_chars].to_string() + "…"
  }
}

///|
pub fn LeftSidebar::new() -> Self {
  try! ({
    let heading = QLabel::new()
    heading.setObjectName("SidebarHeading")
    heading.setText("会话")

    let count_label = QLabel::new()
    count_label.setObjectName("SidebarCount")
    count_label.setText("0 个")

    let new_chat = QPushButton::new()
    new_chat.setObjectName("SidebarNewChatButton")
    new_chat.setText("＋")
    new_chat.setFixedSize(28, 28)

    let header = QBoxLayout::horizontal()
    header.setContentsMargins(0, 0, 0, 0)
    header.setSpacing(10)
    header.addWidget(heading)
    header.addStretch(stretch=1)
    header.addWidget(count_label)
    header.addWidget(new_chat)
    let _ = header.setAlignment(count_label, Alignment::v(Center))
    let _ = header.setAlignment(new_chat, Alignment::v(Center))

    let list = QBoxLayout::vertical()
    list.setContentsMargins(0, 0, 0, 0)
    list.setSpacing(6)
    list.addStretch(stretch=1)

    let list_root = QWidget::new()
    list_root.setObjectName("SidebarScrollContent")
    list_root.setLayout(list)
    list_root.setMinimumWidth(0)
    list_root.setSizePolicy(QSizePolicy::new(Ignored, Preferred))

    let scroll = QScrollArea::new()
    scroll.setObjectName("SidebarScroll")
    scroll.setFrameShape(NoFrame)
    scroll.setWidgetResizable(true)
    scroll.setAlignment(Alignment::v(Top))
    scroll.setHorizontalScrollBarPolicy(AlwaysOff)
    scroll.setWidget(list_root)

    let layout = QBoxLayout::vertical()
    layout.setContentsMargins(14, 14, 14, 14)
    layout.setSpacing(12)
    layout.addLayout(header)
    layout.addWidget(scroll, stretch=1)

    let root = QWidget::new()
    root.setObjectName("LeftSidebar")
    root.setLayout(layout)
    root.setStyleSheet(sidebar_style)
    root.setMinimumWidth(sidebar_min_width())
    root.setMaximumWidth(sidebar_max_width())

    let buttons = QButtonGroup::newWithParent(root)
    buttons.setExclusive(false)

    new_chat.setFlat(true)
    new_chat.setFocusPolicy(No)

    LeftSidebar::{
      root,
      count_label,
      new_chat,
      list,
      buttons,
      rows: [],
      interactions_enabled: true,
    }
  })
}

///|
pub fn LeftSidebar::chat_created(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.new_chat.clicked()
}

///|
pub fn LeftSidebar::set_state(
  self : Self,
  titles : Array[String],
  current_index : Int?,
) -> Unit raise NullptrError {
  self.rebuild_rows(titles)
  self.apply_count(titles.length())
  self.apply_selection(current_index)
  self.apply_interactions_enabled()
}

///|
pub fn LeftSidebar::conversation_selected(
  self : Self,
) -> Signal[Int] raise NullptrError {
  self.buttons.idClicked()
}

///|
pub fn LeftSidebar::set_interactions_enabled(
  self : Self,
  enabled : Bool,
) -> Unit raise NullptrError {
  self.interactions_enabled = enabled
  self.apply_interactions_enabled()
}

///|
fn LeftSidebar::rebuild_rows(
  self : Self,
  titles : Array[String],
) -> Unit raise NullptrError {
  self.clear_rows()
  for i in 0..<titles.length() {
    let button = QPushButton::new()
    button.setObjectName("SidebarConversationButton")
    button.setCheckable(true)
    button.setFlat(true)
    button.setFocusPolicy(No)
    button.setText(sidebar_title_preview(titles[i]))
    button.setToolTip(titles[i])
    button.setFixedHeight(40)
    button.setMinimumWidth(0)
    button.setSizePolicy(QSizePolicy::new(Ignored, Fixed))
    button.setEnabled(self.interactions_enabled)
    self.buttons.addButton(button, id=i)
    self.list.insertWidget(i, button)
    self.rows.push(button)
  }
}

///|
fn LeftSidebar::clear_rows(self : Self) -> Unit raise NullptrError {
  for row in self.rows {
    self.buttons.removeButton(row)
    self.list.removeWidget(row)
    row.deleteLater()
  }
  self.rows = []
}

///|
fn LeftSidebar::apply_selection(
  self : Self,
  current_index : Int?,
) -> Unit raise NullptrError {
  for i in 0..<self.rows.length() {
    let checked = match current_index {
      Some(index) => index == i
      None => false
    }
    self.rows[i].setChecked(checked)
  }
}

///|
fn LeftSidebar::apply_count(
  self : Self,
  total : Int,
) -> Unit raise NullptrError {
  self.count_label.setText("\{total} 个")
}

///|
fn LeftSidebar::apply_interactions_enabled(
  self : Self,
) -> Unit raise NullptrError {
  self.new_chat.setEnabled(self.interactions_enabled)
  for row in self.rows {
    row.setEnabled(self.interactions_enabled)
  }
}

///|
pub impl AsObject for LeftSidebar with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for LeftSidebar with as_widget(self) {
  self.root
}
