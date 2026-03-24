///|
pub struct ToolBar {
  root : QToolBar
  new_chat : QAction
  toggle_sidebar : QAction
  switch : ChatTreeSwitch
  settings : QAction
}

///|
pub fn ToolBar::new() -> Self {
  try! ({
    let root = QToolBar::new()
    root.setObjectName("ToolBar")
    root.setMovable(false)
    root.setFloatable(false)

    let new_chat = root.addActionWithText("新建对话")

    let toggle_sidebar = root.addActionWithText("隐藏侧边栏")
    toggle_sidebar.setCheckable(true)

    let spacer = QWidget::new()
    spacer.setSizePolicy(QSizePolicy::new(Expanding, Preferred))
    let _ = root.addWidget(spacer)

    let switch = ChatTreeSwitch::new()
    let _ = root.addWidget(switch)

    let settings = root.addActionWithText("设置")

    ToolBar::{ root, new_chat, toggle_sidebar, switch, settings }
  })
}

///|
pub fn ToolBar::chat_created(self : Self) -> Signal[Bool] raise NullptrError {
  self.new_chat.triggered()
}

///|
pub fn ToolBar::sidebar_toggled(self : Self) -> Signal[Bool] raise NullptrError {
  self.toggle_sidebar.toggled()
}

///|
pub fn ToolBar::chat_switched(self : Self) -> Signal[Bool] raise NullptrError {
  self.switch.chat_switched()
}

///|
pub fn ToolBar::tree_switched(self : Self) -> Signal[Bool] raise NullptrError {
  self.switch.tree_switched()
}

///|
pub fn ToolBar::settings_clicked(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.settings.triggered()
}

///|
pub impl AsObject for ToolBar with as_object(self) {
  self.root.as_object()
}

///|
pub impl AsWidget for ToolBar with as_widget(self) {
  self.root.as_widget()
}

///|
pub fn ToolBar::as_tool_bar(self : Self) -> QToolBar {
  self.root
}
