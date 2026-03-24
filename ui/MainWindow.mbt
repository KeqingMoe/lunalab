///|
pub struct MainWindow {
  root : QMainWindow
  toolbar : ToolBar
  sidebar : LeftSidebar
  chat : ChatPage
  tree : TreePage
}

///|
pub fn MainWindow::new() -> Self {
  try! ({
    let toolbar = ToolBar::new()
    let sidebar = LeftSidebar::new()
    let chat = ChatPage::new()
    let tree = TreePage::new()

    let main = QStackedWidget::new()
    let _ = main.addWidget(chat)
    let _ = main.addWidget(tree)

    let _ = toolbar.sidebar_toggled().connect(f => sidebar.setVisible(!f))
    let _ = toolbar.chat_switched().connect(_ => main.setCurrentWidget(chat))
    let _ = toolbar.tree_switched().connect(_ => main.setCurrentWidget(tree))
    let _ = toolbar
      .settings_clicked()
      .connect(_ => SettingsDialog::new().show())

    let central = QSplitter::new()
    central.addWidget(sidebar)
    central.addWidget(main)
    central.setSizes([1, 3])

    let root = QMainWindow::new()
    root.setObjectName("MainWindow")
    root.setWindowTitle("LunaLab")
    root.addToolBar(toolbar.as_tool_bar())
    root.setCentralWidget(central)
    root.setMinimumSize(800, 600)
    root.resize(1000, 720)

    MainWindow::{ root, toolbar, sidebar, chat, tree }
  })
}

///|
pub impl AsObject for MainWindow with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for MainWindow with as_widget(self) {
  self.root.as_widget()
}
