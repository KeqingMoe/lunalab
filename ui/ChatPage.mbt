///|
pub struct ChatPage {
  root : QWidget
  mut tree : ChatTree
  chat_view : ChatView
  composer : ComposerPanel
  manager : QNetworkAccessManager
  mutation_notifier : QPushButton
  busy_notifier : QPushButton
}

///|
pub fn ChatPage::new() -> Self {
  try! ({
    let tree = new_chat_tree()
    let chat_view = ChatView::new()
    let composer = ComposerPanel::new()
    let manager = QNetworkAccessManager::new()

    let layout = QBoxLayout::vertical()
    layout.addWidget(chat_view)
    layout.addWidget(composer)
    layout.setContentsMargins(0, 0, 0, 0)
    layout.setSpacing(0)

    let root = QWidget::new()
    root.setObjectName("ChatPage")
    root.setLayout(layout)

    manager.setParent(root)

    let mutation_notifier = QPushButton::new()
    mutation_notifier.setParent(root)
    mutation_notifier.setVisible(false)

    let busy_notifier = QPushButton::new()
    busy_notifier.setParent(root)
    busy_notifier.setVisible(false)
    busy_notifier.setCheckable(true)

    let page = ChatPage::{
      root,
      tree,
      chat_view,
      composer,
      manager,
      mutation_notifier,
      busy_notifier,
    }

    let _ = page.composer.send_clicked().connect(_ => page.submit_message())
    let _ = page.composer
      .generate_clicked()
      .connect(_ => page.generate_assistant_message())
    let _ = page.composer.text_changed().connect(_ => page.sync_view())

    page.sync_view()
    page
  })
}

///|
pub fn ChatPage::load_tree(
  self : Self,
  tree : ChatTree,
) -> Unit raise NullptrError {
  self.tree = tree
  self.composer.clear()
  self.sync_view()
}

///|
pub fn ChatPage::new_chat(self : Self) -> Unit raise NullptrError {
  self.tree = new_chat_tree()
  self.composer.clear()
  self.sync_view()
}

///|
pub fn ChatPage::conversation_mutated(
  self : Self,
) -> Signal[Bool] raise NullptrError {
  self.mutation_notifier.clicked()
}

///|
pub fn ChatPage::busy_changed(self : Self) -> Signal[Bool] raise NullptrError {
  self.busy_notifier.toggled()
}

///|
fn ChatPage::submit_message(self : Self) -> Unit raise NullptrError {
  guard !self.is_busy() else { () }

  let text = self.composer.text()
  guard !text.is_blank() else {
    self.sync_view()
    ()
  }

  match self.composer.current_mode() {
    Auto => {
      ignore(self.tree.commit(Message::user(text)))
      self.composer.clear()
      self.sync_view()
      self.notify_mutation()
      self.request_assistant_message(self.tree)
      return
    }
    Append =>
      ignore(
        self.tree.commit(message_for_role(self.composer.selected_role(), text)),
      )
  }

  self.composer.clear()
  self.sync_view()
  self.notify_mutation()
}

///|
fn ChatPage::generate_assistant_message(self : Self) -> Unit raise NullptrError {
  guard !self.is_busy() else { () }
  guard self.composer.current_mode() is Append else { () }
  self.request_assistant_message(self.tree)
}

///|
fn ChatPage::sync_view(self : Self) -> Unit raise NullptrError {
  self.chat_view.set_messages(conversation_messages(self.tree))
  self.composer.set_branch_hint(head_hint(self.tree))
  self.composer.set_send_enabled(self.composer.has_text())
}

///|
fn ChatPage::request_assistant_message(
  self : Self,
  target_tree : ChatTree,
) -> Unit raise NullptrError {
  match openrouter_missing_config_message() {
    Some(message) => {
      ignore(target_tree.commit(Message::assistant(message)))
      if physical_equal(self.tree, target_tree) {
        self.sync_view()
      }
      self.notify_mutation()
    }
    None => {
      let request = QNetworkRequest::new(openrouter_request_url())
      let body = build_openrouter_chat_request_body(
        conversation_messages(target_tree),
      )

      request.setContentLength(body.length().to_int64())
      request.setContentType("application/json")
      request.setTransferTimeout(120000)
      request.setRawHeader(
        "Authorization",
        @utf8.encode("Bearer \{openrouter_api_key().trim().to_string()}"),
      )

      self.set_busy(true)

      let reply = self.manager.post(request, body)
      let _ = reply
        .finished()
        .connect(_ => self.finish_assistant_request(reply, target_tree))
    }
  }
}

///|
fn ChatPage::finish_assistant_request(
  self : Self,
  reply : QNetworkReply,
  target_tree : ChatTree,
) -> Unit raise NullptrError {
  let raw_text = @utf8.decode_lossy(reply.readAll())
  let assistant_text = if reply.error() is NoError {
    extract_openrouter_response_text(raw_text)
  } else {
    openrouter_failure_message(
      reply.httpStatusCode(),
      reply.httpReasonPhrase(),
      reply.errorString(),
      raw_text,
    )
  }

  ignore(target_tree.commit(Message::assistant(assistant_text)))
  if physical_equal(self.tree, target_tree) {
    self.sync_view()
  }

  self.set_busy(false)
  self.notify_mutation()
  reply.deleteLater()
}

///|
fn ChatPage::set_busy(self : Self, busy : Bool) -> Unit raise NullptrError {
  if self.busy_notifier.isChecked() != busy {
    self.busy_notifier.setChecked(busy)
  }
  self.composer.set_busy(busy)
}

///|
fn ChatPage::is_busy(self : Self) -> Bool raise NullptrError {
  self.busy_notifier.isChecked()
}

///|
fn ChatPage::notify_mutation(self : Self) -> Unit raise NullptrError {
  self.mutation_notifier.click()
}

///|
fn message_for_role(role : Role, content : String) -> Message {
  match role {
    System => Message::system(content)
    User => Message::user(content)
    Assistant => Message::assistant(content)
  }
}

///|
pub impl AsObject for ChatPage with as_object(self) {
  self.as_widget().as_object()
}

///|
pub impl AsWidget for ChatPage with as_widget(self) {
  self.root
}
