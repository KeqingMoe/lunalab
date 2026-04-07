///|
pub struct MainWindow {
  root : QMainWindow
  toolbar : ToolBar
  splitter : QSplitter
  sidebar : LeftSidebar
  chat : ChatPage
  tree : TreePage
  app_state : AppStateStore
  conversations : Array[ConversationSession]
  mut current_index : Int?
  mut draft : ConversationSession?
  mut sidebar_width : Int
  mut sidebar_hidden : Bool
}

///|
pub fn MainWindow::new() -> Self {
  try! ({
    let app_state = AppStateStore::new(snapshot=load_app_state_snapshot())
    let toolbar = ToolBar::new()
    let sidebar = LeftSidebar::new()
    let chat = ChatPage::new()
    let tree = TreePage::new()
    let conversations = app_state.conversation_sessions()
    let current_index = app_state.current_index()
    let draft = app_state.draft_session()

    let main = QStackedWidget::new()
    main.setObjectName("MainStack")
    let _ = main.addWidget(chat)
    let _ = main.addWidget(tree)

    let central = QSplitter::new()
    central.setObjectName("MainSplitter")
    central.addWidget(sidebar)
    central.addWidget(main)
    central.setHandleWidth(1)
    central.setChildrenCollapsible(true)
    central.setCollapsible(0, true)
    central.setStretchFactor(0, 1)
    central.setStretchFactor(1, 3)

    let root = QMainWindow::new()
    root.setObjectName("MainWindow")
    root.setWindowTitle("LunaLab")
    root.addToolBar(toolbar.as_tool_bar())
    root.setCentralWidget(central)
    root.setMinimumSize(800, 600)
    root.resize(1000, 720)
    central.setSizes([sidebar_default_width(), 750])

    let window = MainWindow::{
      root,
      toolbar,
      splitter: central,
      sidebar,
      chat,
      tree,
      app_state,
      conversations,
      current_index,
      draft,
      sidebar_width: app_state.sidebar_width(),
      sidebar_hidden: app_state.sidebar_hidden(),
    }

    match window.current_index {
      Some(index) if index >= 0 && index < window.conversations.length() =>
        window.chat.load_tree(window.conversations[index].tree)
      _ =>
        match window.draft {
          Some(draft) => window.chat.load_tree(draft.tree)
          None => ()
        }
    }
    window.chat.set_provider(window.app_state.current_provider())
    window.sync_sidebar()
    if window.sidebar_hidden {
      window.splitter.setSizes([0, 1])
    } else {
      window.splitter.setSizes([window.sidebar_width, 750])
    }
    window.toolbar.set_sidebar_hidden(window.sidebar_hidden)

    let _ = window.sidebar
      .chat_created()
      .connect(_ => window.start_new_conversation())
    let _ = window.sidebar
      .chat_created()
      .connect(_ => main.setCurrentWidget(chat))
    let _ = window.chat
      .conversation_mutated()
      .connect(_ => window.sync_conversation_after_mutation())
    let _ = window.chat
      .busy_changed()
      .connect(busy => window.sync_chat_busy(busy))
    let _ = window.sidebar
      .conversation_selected()
      .connect(index => window.select_conversation_from_sidebar(index))
    let _ = window.toolbar
      .sidebar_toggled()
      .connect(hidden => window.request_sidebar_hidden(hidden))
    let _ = window.splitter
      .splitterMoved()
      .connect(_ => window.sync_sidebar_state_from_splitter())
    let _ = window.toolbar
      .chat_switched()
      .connect(_ => main.setCurrentWidget(chat))
    let _ = window.toolbar
      .tree_switched()
      .connect(_ => main.setCurrentWidget(tree))
    let _ = window.toolbar
      .settings_clicked()
      .connect(_ => window.open_settings_dialog())

    window
  })
}

///|
fn MainWindow::conversation_snapshot(self : Self) -> AppStateSnapshot {
  self.app_state.set_conversation_state(
    self.conversations,
    self.current_index,
    self.draft,
  )
  self.app_state.snapshot()
}

///|
fn MainWindow::persist_conversation_state(
  self : Self,
  changed_session_ids : Array[String],
  removed_session_ids? : Array[String],
) -> Unit {
  save_conversation_state(
    self.conversation_snapshot(),
    changed_session_ids,
    removed_session_ids?,
  )
}

///|
fn MainWindow::persist_ui_state(self : Self) -> Unit {
  self.app_state.set_sidebar_state(self.sidebar_width, self.sidebar_hidden)
  save_ui_state(self.app_state.snapshot())
}

///|
fn MainWindow::open_settings_dialog(self : Self) -> Unit raise NullptrError {
  let dialog = SettingsDialog::new(
    self.app_state.providers(),
    self.app_state.current_provider_id(),
  )
  dialog.as_dialog().setParent(self.root)
  let _ = dialog
    .as_dialog()
    .accepted()
    .connect(_ => {
      self.app_state.set_providers(
        dialog.providers(),
        dialog.current_provider_id(),
      )
      self.chat.set_provider(self.app_state.current_provider())
      save_settings_state(self.app_state.snapshot())
    })
  dialog.show()
}

///|
fn MainWindow::sync_chat_busy(
  self : Self,
  busy : Bool,
) -> Unit raise NullptrError {
  self.sidebar.set_interactions_enabled(!busy)
}

///|
fn MainWindow::start_new_conversation(self : Self) -> Unit raise NullptrError {
  let previous_draft_id = self.draft.map(draft => draft.id)
  self.draft = Some(self.app_state.new_session())
  self.current_index = None
  match self.draft {
    Some(draft) => self.chat.load_tree(draft.tree)
    None => ()
  }
  self.sync_sidebar()
  let changed_session_ids = match self.draft {
    Some(draft) => [draft.id]
    None => []
  }
  self.persist_conversation_state(
    changed_session_ids,
    removed_session_ids=previous_draft_id.map(id => [id]).unwrap_or([]),
  )
}

///|
fn MainWindow::select_conversation_from_sidebar(
  self : Self,
  display_index : Int,
) -> Unit raise NullptrError {
  guard sidebar_model_index(self.conversations.length(), display_index)
    is Some(index) else {
    ()
  }
  self.select_conversation(index)
}

///|
fn MainWindow::select_conversation(
  self : Self,
  index : Int,
) -> Unit raise NullptrError {
  guard index >= 0 else { () }
  guard index < self.conversations.length() else { () }
  guard self.current_index != Some(index) else { () }

  self.draft = None
  self.current_index = Some(index)
  self.chat.load_tree(self.conversations[index].tree)
  self.sync_sidebar()
  self.persist_conversation_state([])
}

///|
fn MainWindow::sync_conversation_after_mutation(
  self : Self,
) -> Unit raise NullptrError {
  let changed_session_ids = []
  match self.current_index {
    Some(index) => {
      self.conversations[index].refresh_title()
      changed_session_ids.push(self.conversations[index].id)
      self.current_index = Some(
        move_conversation_to_end(self.conversations, index),
      )
    }
    None =>
      match self.draft {
        Some(draft) => {
          guard conversation_has_messages(draft.tree) else {
            self.sync_sidebar()
            ()
          }

          draft.refresh_title()
          changed_session_ids.push(draft.id)
          self.conversations.push(draft)
          self.current_index = Some(self.conversations.length() - 1)
          self.draft = None
        }
        None => ()
      }
  }

  self.sync_sidebar()
  self.persist_conversation_state(changed_session_ids)
}

///|
fn MainWindow::request_sidebar_hidden(
  self : Self,
  hidden : Bool,
) -> Unit raise NullptrError {
  guard hidden != self.sidebar_hidden else {
    self.toolbar.set_sidebar_hidden(hidden)
  }

  self.sidebar_hidden = hidden
  if hidden {
    self.splitter.setSizes([0, 1])
  } else {
    let width = self.sidebar_width
      .max(sidebar_min_width())
      .min(sidebar_max_width())
    self.splitter.setSizes([width, 1])
  }
  self.toolbar.set_sidebar_hidden(hidden)
  self.persist_ui_state()
}

///|
fn MainWindow::sync_sidebar_state_from_splitter(
  self : Self,
) -> Unit raise NullptrError {
  let sizes = self.splitter.sizes()
  guard sizes.length() >= 1 else { () }

  let width = sizes[0]
  if width <= sidebar_collapse_threshold() {
    if !self.sidebar_hidden {
      self.sidebar_hidden = true
      self.toolbar.set_sidebar_hidden(true)
    }
  } else {
    self.sidebar_width = width.min(sidebar_max_width())
    if self.sidebar_hidden {
      self.sidebar_hidden = false
      self.toolbar.set_sidebar_hidden(false)
    }
  }
  self.persist_ui_state()
}

///|
fn MainWindow::sync_sidebar(self : Self) -> Unit raise NullptrError {
  self.sidebar.set_state(
    conversation_titles_for_sidebar(self.conversations),
    sidebar_display_index(self.conversations.length(), self.current_index),
  )
}

///|
pub impl AsObject for MainWindow with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for MainWindow with as_widget(self) {
  self.root.as_widget()
}
