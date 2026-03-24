///|
pub struct ComposerPanel {
  root : QWidget
  editor : QPlainTextEdit
  send_btn : QPushButton
}

///|
pub fn ComposerPanel::new() -> Self {
  try! ({
    let editor = QPlainTextEdit::auto_growing()
    editor.setObjectName("MessageEditor")
    editor.setPlaceholderText("请输入文本")

    let actions = QBoxLayout::horizontal()
    actions.setContentsMargins(0, 0, 0, 0)
    actions.setSpacing(8)

    let attach_btn = QPushButton::new()
    attach_btn.setText("Attach")

    let branch_hint = QLabel::new()
    branch_hint.setObjectName("BranchHint")
    branch_hint.setText("当前：沿当前节点继续")

    let send_btn = QPushButton::new()
    send_btn.setObjectName("SendButton")
    send_btn.setText("发送")

    actions.addWidget(attach_btn)
    actions.addWidget(branch_hint)
    actions.addStretch(stretch=1)
    actions.addWidget(send_btn)

    let layout = QBoxLayout::vertical()
    layout.addWidget(editor)
    layout.addLayout(actions)
    layout.setContentsMargins(12, 10, 12, 12)
    layout.setSpacing(8)

    let root = QWidget::new()
    root.setObjectName("ComposerPanel")
    root.setLayout(layout)

    ComposerPanel::{ root, editor, send_btn }
  })
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
