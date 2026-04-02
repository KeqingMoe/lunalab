///|
pub struct ComposerPanel {
  root : QWidget
  auto_mode_btn : QToolButton
  append_mode_btn : QToolButton
  role_switch : QWidget
  role_group : QButtonGroup
  editor : QPlainTextEdit
  branch_hint : QLabel
  generate_btn : QPushButton
  send_btn : QPushButton
  mut busy : Bool
}

///|
let composer_panel_style : String =
  #|QWidget#ComposerPanel {
  #|  background: #ffffff;
  #|  border-top: 1px solid #e4e7ec;
  #|}
  #|
  #|QPlainTextEdit#MessageEditor {
  #|  background: #ffffff;
  #|  color: #101828;
  #|  border: 1px solid #d0d5dd;
  #|  border-radius: 12px;
  #|  padding: 8px 10px;
  #|  selection-background-color: #b2ccff;
  #|}
  #|
  #|QPlainTextEdit#MessageEditor:focus {
  #|  border: 1px solid #84adff;
  #|  background: #ffffff;
  #|}
  #|
  #|QLabel#BranchHint {
  #|  background: transparent;
  #|  color: #667085;
  #|}
  #|
  #|QWidget#ComposerModeSwitch,
  #|QWidget#ComposerRoleSwitch {
  #|  background: transparent;
  #|  border: none;
  #|}
  #|
  #|QWidget#ComposerModeDivider,
  #|QWidget#ComposerRoleDivider {
  #|  background: #d0d5dd;
  #|}
  #|
  #|QToolButton#ComposerAutoModeButton,
  #|QToolButton#ComposerAppendModeButton,
  #|QToolButton#ComposerRoleUserButton,
  #|QToolButton#ComposerRoleSystemButton,
  #|QToolButton#ComposerRoleAssistantButton {
  #|  background: #eef2f6;
  #|  color: #475467;
  #|  border-top: 1px solid #d0d5dd;
  #|  border-bottom: 1px solid #d0d5dd;
  #|  padding: 0 12px;
  #|  font-weight: 700;
  #|}
  #|
  #|QToolButton#ComposerAutoModeButton {
  #|  border-left: 1px solid #d0d5dd;
  #|  border-right: none;
  #|  border-top-left-radius: 17px;
  #|  border-bottom-left-radius: 17px;
  #|  border-top-right-radius: 0;
  #|  border-bottom-right-radius: 0;
  #|}
  #|
  #|QToolButton#ComposerAppendModeButton {
  #|  border-left: none;
  #|  border-right: 1px solid #d0d5dd;
  #|  border-top-left-radius: 0;
  #|  border-bottom-left-radius: 0;
  #|  border-top-right-radius: 17px;
  #|  border-bottom-right-radius: 17px;
  #|}
  #|
  #|QToolButton#ComposerRoleUserButton {
  #|  border-left: 1px solid #d0d5dd;
  #|  border-right: none;
  #|  border-top-left-radius: 17px;
  #|  border-bottom-left-radius: 17px;
  #|  border-top-right-radius: 0;
  #|  border-bottom-right-radius: 0;
  #|}
  #|
  #|QToolButton#ComposerRoleSystemButton {
  #|  border-left: none;
  #|  border-right: none;
  #|  border-radius: 0;
  #|}
  #|
  #|QToolButton#ComposerRoleAssistantButton {
  #|  border-left: none;
  #|  border-right: 1px solid #d0d5dd;
  #|  border-top-left-radius: 0;
  #|  border-bottom-left-radius: 0;
  #|  border-top-right-radius: 17px;
  #|  border-bottom-right-radius: 17px;
  #|}
  #|
  #|QToolButton#ComposerAutoModeButton:hover,
  #|QToolButton#ComposerAppendModeButton:hover,
  #|QToolButton#ComposerRoleUserButton:hover,
  #|QToolButton#ComposerRoleSystemButton:hover,
  #|QToolButton#ComposerRoleAssistantButton:hover {
  #|  background: #f8fafc;
  #|}
  #|
  #|QToolButton#ComposerAutoModeButton:checked,
  #|QToolButton#ComposerAppendModeButton:checked,
  #|QToolButton#ComposerRoleUserButton:checked,
  #|QToolButton#ComposerRoleSystemButton:checked,
  #|QToolButton#ComposerRoleAssistantButton:checked {
  #|  background: #ffffff;
  #|  color: #175cd3;
  #|}
  #|
  #|QToolButton#ComposerAutoModeButton:pressed,
  #|QToolButton#ComposerAppendModeButton:pressed,
  #|QToolButton#ComposerRoleUserButton:pressed,
  #|QToolButton#ComposerRoleSystemButton:pressed,
  #|QToolButton#ComposerRoleAssistantButton:pressed {
  #|  background: #e2e8f0;
  #|}
  #|
  #|QPushButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border: 1px solid #d0d5dd;
  #|  border-radius: 12px;
  #|  padding: 9px 14px;
  #|  font-weight: 600;
  #|}
  #|
  #|QPushButton:hover {
  #|  background: #f8fafc;
  #|  border-color: #98a2b3;
  #|}
  #|
  #|QPushButton:pressed {
  #|  background: #eef2f6;
  #|}
  #|
  #|QPushButton:disabled {
  #|  background: #f2f4f7;
  #|  color: #98a2b3;
  #|  border-color: #e4e7ec;
  #|}
  #|
  #|QPushButton#SendButton {
  #|  background: #175cd3;
  #|  color: #ffffff;
  #|  border: 1px solid #175cd3;
  #|}
  #|
  #|QPushButton#SendButton:hover {
  #|  background: #1849a9;
  #|  border-color: #1849a9;
  #|}
  #|
  #|QPushButton#SendButton:pressed {
  #|  background: #153e75;
  #|  border-color: #153e75;
  #|}
  #|
  #|QPushButton#SendButton:disabled {
  #|  background: #b2ccff;
  #|  color: #eff4ff;
  #|  border-color: #b2ccff;
  #|}
  #|
  #|QPushButton#GenerateReplyButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border-color: #d0d5dd;
  #|}

///|
pub fn ComposerPanel::new() -> Self {
  try! ({
    let editor = QPlainTextEdit::auto_growing()
    editor.setObjectName("MessageEditor")
    editor.setPlaceholderText("请输入文本")

    let actions = QBoxLayout::horizontal()
    actions.setContentsMargins(0, 0, 0, 0)
    actions.setSpacing(8)

    let auto_mode_btn = QToolButton::new()
    auto_mode_btn.setObjectName("ComposerAutoModeButton")
    auto_mode_btn.setText("自动")
    auto_mode_btn.setCheckable(true)
    auto_mode_btn.setChecked(true)
    auto_mode_btn.setFixedHeight(34)

    let append_mode_btn = QToolButton::new()
    append_mode_btn.setObjectName("ComposerAppendModeButton")
    append_mode_btn.setText("追加")
    append_mode_btn.setCheckable(true)
    append_mode_btn.setFixedHeight(34)

    let mode_divider = QWidget::new()
    mode_divider.setObjectName("ComposerModeDivider")
    mode_divider.setMinimumWidth(1)
    mode_divider.setMaximumWidth(1)
    mode_divider.setFixedHeight(34)

    let mode_layout = QBoxLayout::horizontal()
    mode_layout.setContentsMargins(0, 0, 0, 0)
    mode_layout.setSpacing(0)
    mode_layout.addWidget(auto_mode_btn)
    mode_layout.addWidget(mode_divider)
    mode_layout.addWidget(append_mode_btn)

    let mode_switch = QWidget::new()
    mode_switch.setObjectName("ComposerModeSwitch")
    mode_switch.setFixedHeight(34)
    mode_switch.setLayout(mode_layout)

    let role_user_btn = QToolButton::new()
    role_user_btn.setObjectName("ComposerRoleUserButton")
    role_user_btn.setText("用户")
    role_user_btn.setCheckable(true)
    role_user_btn.setChecked(true)
    role_user_btn.setFixedHeight(34)

    let role_system_btn = QToolButton::new()
    role_system_btn.setObjectName("ComposerRoleSystemButton")
    role_system_btn.setText("系统")
    role_system_btn.setCheckable(true)
    role_system_btn.setFixedHeight(34)

    let role_assistant_btn = QToolButton::new()
    role_assistant_btn.setObjectName("ComposerRoleAssistantButton")
    role_assistant_btn.setText("助手")
    role_assistant_btn.setCheckable(true)
    role_assistant_btn.setFixedHeight(34)

    let role_divider_a = QWidget::new()
    role_divider_a.setObjectName("ComposerRoleDivider")
    role_divider_a.setMinimumWidth(1)
    role_divider_a.setMaximumWidth(1)
    role_divider_a.setFixedHeight(34)

    let role_divider_b = QWidget::new()
    role_divider_b.setObjectName("ComposerRoleDivider")
    role_divider_b.setMinimumWidth(1)
    role_divider_b.setMaximumWidth(1)
    role_divider_b.setFixedHeight(34)

    let role_layout = QBoxLayout::horizontal()
    role_layout.setContentsMargins(0, 0, 0, 0)
    role_layout.setSpacing(0)
    role_layout.addWidget(role_user_btn)
    role_layout.addWidget(role_divider_a)
    role_layout.addWidget(role_system_btn)
    role_layout.addWidget(role_divider_b)
    role_layout.addWidget(role_assistant_btn)

    let role_switch = QWidget::new()
    role_switch.setObjectName("ComposerRoleSwitch")
    role_switch.setFixedHeight(34)
    role_switch.setLayout(role_layout)

    let branch_hint = QLabel::new()
    branch_hint.setObjectName("BranchHint")
    branch_hint.setText("当前：空白会话")

    let generate_btn = QPushButton::new()
    generate_btn.setObjectName("GenerateReplyButton")
    generate_btn.setText("生成回复")
    generate_btn.setFixedHeight(34)

    let send_btn = QPushButton::new()
    send_btn.setObjectName("SendButton")
    send_btn.setText("发送")
    send_btn.setFixedHeight(34)
    send_btn.setEnabled(false)

    actions.addWidget(mode_switch)
    actions.addWidget(role_switch)
    actions.addWidget(branch_hint)
    actions.addStretch(stretch=1)
    actions.addWidget(generate_btn)
    actions.addWidget(send_btn)

    let layout = QBoxLayout::vertical()
    layout.addWidget(editor)
    layout.addLayout(actions)
    layout.setContentsMargins(12, 10, 12, 12)
    layout.setSpacing(8)

    let root = QWidget::new()
    root.setObjectName("ComposerPanel")
    root.setLayout(layout)
    root.setStyleSheet(composer_panel_style)

    let mode_group = QButtonGroup::newWithParent(root)
    mode_group.setExclusive(true)
    mode_group.addButton(auto_mode_btn)
    mode_group.addButton(append_mode_btn)

    let role_group = QButtonGroup::newWithParent(root)
    role_group.setExclusive(true)
    role_group.addButton(role_user_btn, id=0)
    role_group.addButton(role_system_btn, id=1)
    role_group.addButton(role_assistant_btn, id=2)

    let panel = ComposerPanel::{
      root,
      auto_mode_btn,
      append_mode_btn,
      role_switch,
      role_group,
      editor,
      branch_hint,
      generate_btn,
      send_btn,
      busy: false,
    }

    let _ = panel.auto_mode_btn.clicked().connect(_ => panel.apply_mode_ui())
    let _ = panel.append_mode_btn.clicked().connect(_ => panel.apply_mode_ui())

    panel.apply_mode_ui()
    panel
  })
}

///|
pub fn ComposerPanel::text(self : Self) -> String raise NullptrError {
  self.editor.toPlainText()
}

///|
pub fn ComposerPanel::clear(self : Self) -> Unit raise NullptrError {
  self.editor.clear()
}

///|
pub fn ComposerPanel::has_text(self : Self) -> Bool raise NullptrError {
  !self.text().is_blank()
}

///|
pub fn ComposerPanel::set_branch_hint(
  self : Self,
  text : String,
) -> Unit raise NullptrError {
  self.branch_hint.setText(text)
}

///|
pub fn ComposerPanel::set_send_enabled(
  self : Self,
  enabled : Bool,
) -> Unit raise NullptrError {
  self.send_btn.setEnabled(enabled && !self.busy)
}

///|
pub fn ComposerPanel::current_mode(
  self : Self,
) -> ComposerMode raise NullptrError {
  if self.append_mode_btn.isChecked() {
    Append
  } else {
    Auto
  }
}

///|
pub fn ComposerPanel::selected_role(self : Self) -> Role raise NullptrError {
  match self.role_group.checkedId() {
    1 => System
    2 => Assistant
    _ => User
  }
}

///|
pub fn ComposerPanel::send_clicked(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.send_btn.clicked()
}

///|
pub fn ComposerPanel::generate_clicked(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.generate_btn.clicked()
}

///|
pub fn ComposerPanel::text_changed(
  self : Self,
) -> Signal[Unit] raise NullptrError {
  self.editor.textChanged()
}

///|
pub fn ComposerPanel::set_busy(
  self : Self,
  busy : Bool,
) -> Unit raise NullptrError {
  self.busy = busy
  self.auto_mode_btn.setEnabled(!busy)
  self.append_mode_btn.setEnabled(!busy)
  self.role_switch.setEnabled(!busy)
  self.editor.setEnabled(!busy)
  self.generate_btn.setEnabled(!busy)
  self.apply_mode_ui()
  self.set_send_enabled(self.has_text())
}

///|
fn ComposerPanel::apply_mode_ui(self : Self) -> Unit raise NullptrError {
  let append_mode = self.current_mode() is Append

  self.role_switch.setVisible(append_mode)
  self.generate_btn.setVisible(append_mode)
  self.generate_btn.setText(
    if self.busy {
      "请求中…"
    } else {
      "生成回复"
    },
  )
  self.send_btn.setText(
    if self.busy {
      "请求中…"
    } else if append_mode {
      "追加"
    } else {
      "发送"
    },
  )
  self.editor.setPlaceholderText(
    if self.busy {
      "正在等待模型回复"
    } else if append_mode {
      "追加一条任意角色消息"
    } else {
      "请输入文本"
    },
  )
}

///|
fn QPlainTextEdit::auto_growing() -> Self {
  try! ({
    let editor = QPlainTextEdit::new()
    editor.setFrameShape(NoFrame)
    editor.setVerticalScrollBarPolicy(AsNeeded)
    editor.setHorizontalScrollBarPolicy(AlwaysOff)
    editor.setSizePolicy(QSizePolicy::new(Expanding, Minimum))
    editor.update_height()

    let _ = QObject::connect(
      editor.document().documentLayout().documentSizeChanged(),
      _ => editor.update_height(),
    )

    editor
  })
}

///|
fn QTextDocument::iter(self : Self) -> Iter[@qt.QTextBlock] {
  let mut it = try! self.begin()
  Iter::new(() => {
    if it.isValid() {
      let ret = it
      it = it.next()
      Some(ret)
    } else {
      None
    }
  })
}

///|
fn QPlainTextEdit::content_height(self : Self) -> Int raise NullptrError {
  let doc = self.document()
  let layout = doc.documentLayout()

  let mut h = doc.documentMargin() * 2
  for block in doc {
    h += layout.blockBoundingRect(block).height()
  }

  h.ceil().to_int()
}

///|
fn QPlainTextEdit::update_height(self : Self) -> Unit raise NullptrError {
  let doc_height = self.content_height()

  let margins = self.contentsMargins()
  let height = doc_height +
    margins.top() +
    margins.bottom() +
    self.frameWidth() * 2

  self.setFixedHeight(height.clamp(min=44, max=160))
}

///|
pub impl AsObject for ComposerPanel with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ComposerPanel with as_widget(self) {
  self.root
}
