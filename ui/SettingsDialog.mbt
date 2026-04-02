///|
pub struct SettingsDialog {
  root : QDialog
}

///|
let settings_dialog_style : String =
  #|QDialog#SettingsDialog {
  #|  background: #ffffff;
  #|}

///|
pub fn SettingsDialog::new() -> Self {
  try! ({
    let root = QDialog::new()
    root.setObjectName("SettingsDialog")
    root.setStyleSheet(settings_dialog_style)
    root.setWindowTitle("设置")
    root.setModal(true)

    SettingsDialog::{ root, }
  })
}

///|
pub impl AsObject for SettingsDialog with as_object(self) {
  self.root.as_object()
}

///|
pub impl AsWidget for SettingsDialog with as_widget(self) {
  self.root.as_widget()
}

///|
pub fn SettingsDialog::as_dialog(self : Self) -> QDialog {
  self.root
}
