///|
pub struct TreePage {
  root : QWidget
}

///|
pub fn TreePage::new() -> Self {
  try! ({
    let root = QWidget::new()
    root.setObjectName("TreePage")

    TreePage::{ root, }
  })
}

///|
pub impl AsObject for TreePage with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for TreePage with as_widget(self) {
  self.root
}
