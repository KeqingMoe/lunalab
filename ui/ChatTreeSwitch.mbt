///|
pub struct ChatTreeSwitch {
  root : QWidget
  chat_btn : QToolButton
  tree_btn : QToolButton
}

///|
let chat_tree_switch_style : String =
  #|QWidget#ChatTreeSwitch {
  #|  background: transparent;
  #|  border: none;
  #|}
  #|
  #|QWidget#ChatTreeDivider {
  #|  background: #d0d5dd;
  #|}
  #|
  #|QToolButton {
  #|  background: #eef2f6;
  #|  color: #475467;
  #|  border-top: 1px solid #d0d5dd;
  #|  border-bottom: 1px solid #d0d5dd;
  #|  padding: 0 14px;
  #|  font-weight: 700;
  #|}
  #|
  #|QToolButton#ChatModeButton {
  #|  border-left: 1px solid #d0d5dd;
  #|  border-right: none;
  #|  border-top-left-radius: 17px;
  #|  border-bottom-left-radius: 17px;
  #|  border-top-right-radius: 0;
  #|  border-bottom-right-radius: 0;
  #|}
  #|
  #|QToolButton#TreeModeButton {
  #|  border-left: none;
  #|  border-right: 1px solid #d0d5dd;
  #|  border-top-left-radius: 0;
  #|  border-bottom-left-radius: 0;
  #|  border-top-right-radius: 17px;
  #|  border-bottom-right-radius: 17px;
  #|}
  #|
  #|QToolButton:hover {
  #|  background: #f8fafc;
  #|}
  #|
  #|QToolButton:checked {
  #|  background: #ffffff;
  #|  color: #175cd3;
  #|}
  #|
  #|QToolButton:pressed {
  #|  background: #e2e8f0;
  #|}

///|
pub fn ChatTreeSwitch::new() -> Self {
  try! ({
    let segment_height = 34

    let chat_btn = QToolButton::new()
    chat_btn.setObjectName("ChatModeButton")
    chat_btn.setText("Chat")
    chat_btn.setCheckable(true)
    chat_btn.setChecked(true)
    chat_btn.setFixedHeight(segment_height)

    let tree_btn = QToolButton::new()
    tree_btn.setObjectName("TreeModeButton")
    tree_btn.setText("Tree")
    tree_btn.setCheckable(true)
    tree_btn.setFixedHeight(segment_height)

    let divider = QWidget::new()
    divider.setObjectName("ChatTreeDivider")
    divider.setMinimumWidth(1)
    divider.setMaximumWidth(1)
    divider.setFixedHeight(segment_height)

    let layout = QBoxLayout::horizontal()
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(0)
    layout.addWidget(chat_btn)
    layout.addWidget(divider)
    layout.addWidget(tree_btn)

    let root = QWidget::new()
    root.setObjectName("ChatTreeSwitch")
    root.setFixedHeight(segment_height)
    root.setLayout(layout)
    root.setStyleSheet(chat_tree_switch_style)

    let group = QButtonGroup::new()
    group.setExclusive(true)
    group.addButton(chat_btn)
    group.addButton(tree_btn)
    group.setParent(root)

    ChatTreeSwitch::{ root, chat_btn, tree_btn }
  })
}

///|
pub fn ChatTreeSwitch::chat_switched(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.chat_btn.clicked()
}

///|
pub fn ChatTreeSwitch::tree_switched(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.tree_btn.clicked()
}

///|
pub impl AsObject for ChatTreeSwitch with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ChatTreeSwitch with as_widget(self) {
  self.root
}
