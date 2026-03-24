///|
pub struct ChatTreeSwitch {
  root : QWidget
  chat_btn : QToolButton
  tree_btn : QToolButton
}

///|
pub fn ChatTreeSwitch::new() -> Self {
  try! ({
    let chat_btn = QToolButton::new()
    chat_btn.setText("Chat")
    chat_btn.setCheckable(true)
    chat_btn.setChecked(true)

    let tree_btn = QToolButton::new()
    tree_btn.setText("Tree")
    tree_btn.setCheckable(true)

    let layout = QBoxLayout::horizontal()
    layout.addWidget(chat_btn)
    layout.addWidget(tree_btn)

    let root = QWidget::new()
    root.setObjectName("ChatTreeSwitch")
    root.setLayout(layout)

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
