///|
pub struct ChatPage {
  root : QWidget
  chat_view : ChatView
  composer : ComposerPanel
}

///|
pub fn ChatPage::new() -> Self {
  try! ({
    let chat_view = ChatView::new()

    let composer = ComposerPanel::new()

    let layout = QBoxLayout::vertical()
    layout.addWidget(chat_view)
    layout.addWidget(composer)

    let root = QWidget::new()
    root.setObjectName("ChatPage")
    root.setLayout(layout)

    ChatPage::{ root, chat_view, composer }
  })
}

///|
pub impl AsObject for ChatPage with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ChatPage with as_widget(self) {
  self.root
}
