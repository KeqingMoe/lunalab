///|
pub struct ConversationTitleDialog {
  root : QDialog
  input : QLineEdit
  hint : QLabel
  confirm_button : QPushButton
}

///|
let conversation_title_dialog_style : String =
  #|QDialog#ConversationTitleDialog {
  #|  background: #ffffff;
  #|}
  #|
  #|QLabel#ConversationTitleDialogTitle {
  #|  background: transparent;
  #|  color: #101828;
  #|  font-size: 18px;
  #|  font-weight: 800;
  #|}
  #|
  #|QLabel#ConversationTitleDialogHint {
  #|  background: transparent;
  #|  color: #667085;
  #|  font-size: 13px;
  #|}
  #|
  #|QLineEdit#ConversationTitleDialogInput {
  #|  color: #101828;
  #|  background: #ffffff;
  #|  border: 1px solid #d0d5dd;
  #|  border-radius: 10px;
  #|  padding: 10px 12px;
  #|  font-size: 14px;
  #|}
  #|
  #|QLineEdit#ConversationTitleDialogInput:focus {
  #|  border-color: #1849a9;
  #|}
  #|
  #|QPushButton#ConversationTitleDialogCancelButton,
  #|QPushButton#ConversationTitleDialogConfirmButton {
  #|  border-radius: 10px;
  #|  padding: 8px 16px;
  #|  font-size: 13px;
  #|  font-weight: 700;
  #|}
  #|
  #|QPushButton#ConversationTitleDialogCancelButton {
  #|  color: #344054;
  #|  background: #ffffff;
  #|  border: 1px solid #d0d5dd;
  #|}
  #|
  #|QPushButton#ConversationTitleDialogConfirmButton {
  #|  color: #ffffff;
  #|  background: #175cd3;
  #|  border: 1px solid #175cd3;
  #|}
  #|
  #|QPushButton#ConversationTitleDialogConfirmButton:disabled {
  #|  color: #d0d5dd;
  #|  background: #98a2b3;
  #|  border-color: #98a2b3;
  #|}

///|
pub fn ConversationTitleDialog::new(initial_title : String) -> Self {
  try! ({
    let root = QDialog::new()
    root.setObjectName("ConversationTitleDialog")
    root.setStyleSheet(conversation_title_dialog_style)
    root.setWindowTitle("修改会话名称")
    root.setModal(true)
    root.setMinimumWidth(420)

    let title = QLabel::new()
    title.setObjectName("ConversationTitleDialogTitle")
    title.setText("修改会话名称")

    let hint = QLabel::new()
    hint.setObjectName("ConversationTitleDialogHint")
    hint.setWordWrap(true)
    hint.setText(
      "请输入新的会话名称。留空会自动恢复为“新对话”。",
    )

    let input = QLineEdit::new()
    input.setObjectName("ConversationTitleDialogInput")
    input.setPlaceholderText(
      "例如：需求讨论 / 调试记录 / API 设计",
    )
    input.setText(initial_title)

    let button_box = QDialogButtonBox::new()
    let cancel_button = QPushButton::new()
    cancel_button.setObjectName("ConversationTitleDialogCancelButton")
    cancel_button.setText("取消")
    button_box.addButton(cancel_button, Reject)

    let confirm_button = QPushButton::new()
    confirm_button.setObjectName("ConversationTitleDialogConfirmButton")
    confirm_button.setText("保存")
    button_box.addButton(confirm_button, Accept)

    let layout = QBoxLayout::vertical()
    layout.setContentsMargins(20, 18, 20, 18)
    layout.setSpacing(12)
    layout.addWidget(title)
    layout.addWidget(hint)
    layout.addWidget(input)
    layout.addSpacing(4)
    layout.addWidget(button_box)
    root.setLayout(layout)

    let dialog = ConversationTitleDialog::{ root, input, hint, confirm_button }

    let _ = QObject::connect(dialog.input.textChanged(), _ => {
      dialog.sync_state()
    })
    let _ = QObject::connect(confirm_button.clicked(), _ => {
      dialog.accept_if_valid()
    })
    let _ = QObject::connect(cancel_button.clicked(), _ => root.reject())

    dialog.sync_state()
    dialog.input.selectAll()
    dialog
  })
}

///|
pub fn ConversationTitleDialog::show(self : Self) -> Unit raise NullptrError {
  self.root.show()
}

///|
pub fn ConversationTitleDialog::title(self : Self) -> String raise NullptrError {
  normalize_conversation_title(self.input.text())
}

///|
pub fn ConversationTitleDialog::as_dialog(self : Self) -> QDialog {
  self.root
}

///|
fn ConversationTitleDialog::sync_state(self : Self) -> Unit raise NullptrError {
  let title = normalize_conversation_title(self.input.text())
  self.confirm_button.setEnabled(!title.is_blank())
  self.hint.setText(
    "请输入新的会话名称。留空会自动恢复为“新对话”。",
  )
}

///|
fn ConversationTitleDialog::accept_if_valid(
  self : Self,
) -> Unit raise NullptrError {
  let title = normalize_conversation_title(self.input.text())
  guard !title.is_blank() else {
    self.hint.setText("会话名称不能为空。")
    self.confirm_button.setEnabled(false)
    ()
  }
  self.root.accept()
}

///|
pub impl AsObject for ConversationTitleDialog with as_object(self) {
  self.root.as_object()
}

///|
pub impl AsWidget for ConversationTitleDialog with as_widget(self) {
  self.root.as_widget()
}
