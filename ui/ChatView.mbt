///|
pub struct ChatView {
  root : QWidget
}

///|
pub fn ChatView::new() -> Self {
  try! ({
    let root = QWidget::new()
    root.setObjectName("ChatView")

    ChatView::{ root, }
  })
}

///|
pub impl AsObject for ChatView with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ChatView with as_widget(self) {
  self.root.as_widget()
}
