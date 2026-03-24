///|
using @qt {type QApplication}

///|
using @ui {type MainWindow}

///|
using @styles {style}

///|
fn main raise {
  let app = QApplication::new(@env.args())
  app.setStyleSheet(style)

  let window = MainWindow::new()
  window.show()

  let _ = app.exec()
}
