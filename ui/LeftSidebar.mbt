///|
pub struct LeftSidebar {
  root : QWidget
}

///|
pub fn LeftSidebar::new() -> Self {
  try! ({
    let root = QWidget::new()
    root.setObjectName("LeftSidebar")

    LeftSidebar::{ root, }
  })
}

///|
pub impl AsObject for LeftSidebar with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for LeftSidebar with as_widget(self) {
  self.root
}
