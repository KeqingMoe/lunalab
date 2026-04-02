///|
pub struct ToolBar {
  root : QToolBar
  toggle_sidebar : QPushButton
  switch : ChatTreeSwitch
  settings : QPushButton
}

///|
let toolbar_style : String =
  #|QToolBar#ToolBar {
  #|  background: #f8fafc;
  #|  border: none;
  #|  border-bottom: 1px solid #e4e7ec;
  #|  spacing: 0px;
  #|}
  #|
  #|QWidget#ToolBarSpacer {
  #|  background: transparent;
  #|}
  #|
  #|QPushButton#ToggleSidebarButton,
  #|QPushButton#SettingsButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border: 1px solid #d7dde6;
  #|  border-radius: 12px;
  #|  padding: 0 10px;
  #|  font-weight: 600;
  #|}
  #|QPushButton#ToggleSidebarButton,
  #|QWidget#ChatTreeSwitch,
  #|QPushButton#SettingsButton {
  #|  margin-left: 7px;
  #|}
  #|
  #|QPushButton#ToggleSidebarButton {
  #|  margin-left: 7px;
  #|}
  #|
  #|QPushButton#SettingsButton {
  #|  margin-right: 7px;
  #|}
  #|
  #|QPushButton#ToggleSidebarButton:hover,
  #|QPushButton#SettingsButton:hover {
  #|  background: #f9fbff;
  #|  border-color: #c7d7fe;
  #|}
  #|
  #|QPushButton#ToggleSidebarButton:pressed,
  #|QPushButton#SettingsButton:pressed {
  #|  background: #eef2f6;
  #|  border-color: #c7d7fe;
  #|}
  #|
  #|QPushButton#ToggleSidebarButton:checked {
  #|  background: #eef4ff;
  #|  color: #175cd3;
  #|  border-color: #b2ccff;
  #|}

///|
pub fn ToolBar::new() -> Self {
  try! ({
    let root = QToolBar::new()
    root.setObjectName("ToolBar")
    root.setStyleSheet(toolbar_style)
    root.setMovable(false)
    root.setFloatable(false)
    root.setFixedHeight(48)

    let toggle_sidebar = QPushButton::new()
    toggle_sidebar.setObjectName("ToggleSidebarButton")
    toggle_sidebar.setText("隐藏侧边栏")
    toggle_sidebar.setCheckable(true)
    toggle_sidebar.setFixedHeight(34)

    let _ = root.addWidget(toggle_sidebar)

    let spacer = QWidget::new()
    spacer.setObjectName("ToolBarSpacer")
    spacer.setSizePolicy(QSizePolicy::new(Expanding, Preferred))
    let _ = root.addWidget(spacer)

    let switch = ChatTreeSwitch::new()
    switch.as_widget().setFixedHeight(34)
    let _ = root.addWidget(switch)

    let settings = QPushButton::new()
    settings.setObjectName("SettingsButton")
    settings.setText("设置")
    settings.setFixedHeight(34)
    let _ = root.addWidget(settings)

    ToolBar::{ root, toggle_sidebar, switch, settings }
  })
}

///|
pub fn ToolBar::sidebar_toggled(self : Self) -> Signal[Bool] raise NullptrError {
  self.toggle_sidebar.toggled()
}

///|
pub fn ToolBar::set_sidebar_hidden(
  self : Self,
  hidden : Bool,
) -> Unit raise NullptrError {
  self.toggle_sidebar.setChecked(hidden)
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
  self.settings.clicked()
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
