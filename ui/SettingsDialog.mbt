///|
pub struct SettingsDialog {
  root : QDialog
  provider_select : QComboBox
  name_input : QLineEdit
  base_url_input : QLineEdit
  model_input : QLineEdit
  api_key_input : QLineEdit
  status_label : QLabel
  add_button : QPushButton
  remove_button : QPushButton
  confirm_button : QPushButton
  providers_store : AppStateStore
}

///|
let settings_dialog_style : String =
  #|QDialog#SettingsDialog {
  #|  background: #ffffff;
  #|}
  #|
  #|QLabel#SettingsTitle {
  #|  color: #101828;
  #|  font-size: 18px;
  #|  font-weight: 800;
  #|}
  #|
  #|QLabel#SettingsHint,
  #|QLabel#SettingsFieldLabel,
  #|QLabel#SettingsStatus {
  #|  color: #667085;
  #|  background: transparent;
  #|}
  #|
  #|QLabel#SettingsStatus {
  #|  color: #344054;
  #|}
  #|
  #|QComboBox#SettingsProviderSelect,
  #|QLineEdit#SettingsNameInput,
  #|QLineEdit#SettingsBaseUrlInput,
  #|QLineEdit#SettingsModelInput,
  #|QLineEdit#SettingsApiKeyInput {
  #|  background: #ffffff;
  #|  color: #101828;
  #|  border: 1px solid #d0d5dd;
  #|  border-radius: 10px;
  #|  padding: 0 10px;
  #|  min-height: 38px;
  #|}
  #|
  #|QComboBox#SettingsProviderSelect:focus,
  #|QLineEdit#SettingsNameInput:focus,
  #|QLineEdit#SettingsBaseUrlInput:focus,
  #|QLineEdit#SettingsModelInput:focus,
  #|QLineEdit#SettingsApiKeyInput:focus {
  #|  border-color: #84adff;
  #|}
  #|
  #|QPushButton#SettingsAddButton,
  #|QPushButton#SettingsRemoveButton,
  #|QPushButton#SettingsCancelButton,
  #|QPushButton#SettingsConfirmButton {
  #|  background: #ffffff;
  #|  color: #344054;
  #|  border: 1px solid #d0d5dd;
  #|  border-radius: 10px;
  #|  padding: 0 14px;
  #|  min-height: 36px;
  #|  font-weight: 600;
  #|}
  #|
  #|QPushButton#SettingsAddButton:hover,
  #|QPushButton#SettingsRemoveButton:hover,
  #|QPushButton#SettingsCancelButton:hover,
  #|QPushButton#SettingsConfirmButton:hover {
  #|  background: #f8fafc;
  #|}
  #|
  #|QPushButton#SettingsConfirmButton {
  #|  background: #175cd3;
  #|  color: #ffffff;
  #|  border-color: #175cd3;
  #|}
  #|
  #|QPushButton#SettingsConfirmButton:hover {
  #|  background: #1849a9;
  #|  border-color: #1849a9;
  #|}
  #|
  #|QPushButton#SettingsRemoveButton:disabled {
  #|  color: #98a2b3;
  #|  background: #f2f4f7;
  #|  border-color: #e4e7ec;
  #|}

///|
pub fn SettingsDialog::new(
  providers : Array[ProviderConfig],
  current_provider_id : String?,
) -> Self {
  try! ({
    let root = QDialog::new()
    root.setObjectName("SettingsDialog")
    root.setStyleSheet(settings_dialog_style)
    root.setWindowTitle("设置")
    root.setModal(true)
    root.setMinimumSize(620, 420)

    let title = QLabel::new()
    title.setObjectName("SettingsTitle")
    title.setText("Provider 设置")

    let hint = QLabel::new()
    hint.setObjectName("SettingsHint")
    hint.setWordWrap(true)
    hint.setText(
      "为聊天页配置多个 provider，并选择当前发送消息使用的 provider。",
    )

    let provider_label = settings_field_label("当前 provider")
    let provider_select = QComboBox::new()
    provider_select.setObjectName("SettingsProviderSelect")
    provider_select.setMinimumWidth(260)

    let add_button = QPushButton::new()
    add_button.setObjectName("SettingsAddButton")
    add_button.setText("新增")

    let remove_button = QPushButton::new()
    remove_button.setObjectName("SettingsRemoveButton")
    remove_button.setText("删除")

    let provider_actions = QBoxLayout::horizontal()
    provider_actions.setContentsMargins(0, 0, 0, 0)
    provider_actions.setSpacing(8)
    provider_actions.addWidget(provider_select)
    provider_actions.addWidget(add_button)
    provider_actions.addWidget(remove_button)

    let provider_row = QBoxLayout::vertical()
    provider_row.setContentsMargins(0, 0, 0, 0)
    provider_row.setSpacing(6)
    provider_row.addWidget(provider_label)
    provider_row.addLayout(provider_actions)

    let name_label = settings_field_label("显示名称")
    let name_input = QLineEdit::new()
    name_input.setObjectName("SettingsNameInput")
    name_input.setPlaceholderText("例如 OpenRouter / OpenAI / 本地网关")

    let base_url_label = settings_field_label("Base URL")
    let base_url_input = QLineEdit::new()
    base_url_input.setObjectName("SettingsBaseUrlInput")
    base_url_input.setPlaceholderText("https://.../chat/completions")

    let model_label = settings_field_label("Model")
    let model_input = QLineEdit::new()
    model_input.setObjectName("SettingsModelInput")
    model_input.setPlaceholderText("例如 openai/gpt-4.1-mini")

    let api_key_label = settings_field_label("API Key")
    let api_key_input = QLineEdit::new()
    api_key_input.setObjectName("SettingsApiKeyInput")
    api_key_input.setEchoMode(Password)
    api_key_input.setPlaceholderText("sk-... / or-v1-...")

    let form = QGridLayout::new()
    form.setContentsMargins(0, 0, 0, 0)
    form.setHorizontalSpacing(16)
    form.setVerticalSpacing(12)
    form.addLayout(provider_row, 0, 0, columnSpan=2)
    form.addWidget(name_label, 1, 0)
    form.addWidget(name_input, 1, 1)
    form.addWidget(base_url_label, 2, 0)
    form.addWidget(base_url_input, 2, 1)
    form.addWidget(model_label, 3, 0)
    form.addWidget(model_input, 3, 1)
    form.addWidget(api_key_label, 4, 0)
    form.addWidget(api_key_input, 4, 1)
    form.setColumnStretch(1, 1)

    let status_label = QLabel::new()
    status_label.setObjectName("SettingsStatus")
    status_label.setWordWrap(true)

    let button_box = QDialogButtonBox::new()
    let cancel_button = QPushButton::new()
    cancel_button.setObjectName("SettingsCancelButton")
    cancel_button.setText("取消")
    button_box.addButton(cancel_button, Reject)

    let confirm_button = QPushButton::new()
    confirm_button.setObjectName("SettingsConfirmButton")
    confirm_button.setText("保存")
    button_box.addButton(confirm_button, Accept)

    let content = QBoxLayout::vertical()
    content.setContentsMargins(20, 18, 20, 18)
    content.setSpacing(14)
    content.addWidget(title)
    content.addWidget(hint)
    content.addLayout(form)
    content.addWidget(status_label)
    content.addStretch(stretch=1)
    content.addWidget(button_box)
    root.setLayout(content)

    let providers_store = AppStateStore::new(snapshot=AppStateSnapshot::{
      providers,
      current_provider_id,
      conversations: [],
      current_index: None,
      draft: None,
      sidebar_width: sidebar_default_width(),
      sidebar_hidden: false,
    })

    let dialog = SettingsDialog::{
      root,
      provider_select,
      name_input,
      base_url_input,
      model_input,
      api_key_input,
      status_label,
      add_button,
      remove_button,
      confirm_button,
      providers_store,
    }

    let _ = QObject::connect(dialog.provider_select.currentIndexChanged(), index => {
      dialog.sync_editor_for_index(index)
    })
    let _ = QObject::connect(dialog.name_input.textChanged(), text => {
      dialog.update_selected_provider_name(text)
    })
    let _ = QObject::connect(dialog.base_url_input.textChanged(), text => {
      dialog.update_selected_provider_base_url(text)
    })
    let _ = QObject::connect(dialog.model_input.textChanged(), text => {
      dialog.update_selected_provider_model(text)
    })
    let _ = QObject::connect(dialog.api_key_input.textChanged(), text => {
      dialog.update_selected_provider_api_key(text)
    })
    let _ = QObject::connect(dialog.add_button.clicked(), _ => {
      dialog.add_provider()
    })
    let _ = QObject::connect(dialog.remove_button.clicked(), _ => {
      dialog.remove_selected_provider()
    })
    let _ = QObject::connect(confirm_button.clicked(), _ => {
      dialog.accept_if_valid()
    })
    let _ = QObject::connect(cancel_button.clicked(), _ => root.reject())

    dialog.reload_provider_select()
    dialog.sync_editor_for_index(dialog.provider_select.currentIndex())
    dialog
  })
}

///|
pub fn SettingsDialog::providers(self : Self) -> Array[ProviderConfig] {
  self.providers_store.providers()
}

///|
pub fn SettingsDialog::current_provider_id(self : Self) -> String? {
  self.providers_store.current_provider_id()
}

///|
pub fn SettingsDialog::show(self : Self) -> Unit raise NullptrError {
  self.root.show()
}

///|
fn SettingsDialog::reload_provider_select(
  self : Self,
) -> Unit raise NullptrError {
  let selected_id = self.providers_store.current_provider_id()
  let previous = self.provider_select.blockSignals(true)
  self.provider_select.clear()
  let providers = self.providers_store.providers()
  let mut selected_index = 0
  for i in 0..<providers.length() {
    self.provider_select.addItem(provider_option_label(providers[i]))
    if selected_id == Some(providers[i].id) {
      selected_index = i
    }
  }
  self.provider_select.setCurrentIndex(selected_index)
  let _ = self.provider_select.blockSignals(previous)
  self.remove_button.setEnabled(providers.length() > 1)
}

///|
fn SettingsDialog::sync_editor_for_index(
  self : Self,
  index : Int,
) -> Unit raise NullptrError {
  let providers = self.providers_store.providers()
  guard index >= 0 && index < providers.length() else {
    self.name_input.clear()
    self.base_url_input.clear()
    self.model_input.clear()
    self.api_key_input.clear()
    self.status_label.setText("没有可编辑的 provider。")
    self.confirm_button.setEnabled(false)
    ()
  }

  let provider = providers[index]
  self.providers_store.set_providers(providers, Some(provider.id))
  set_line_edit_text(self.name_input, provider.name)
  set_line_edit_text(self.base_url_input, provider.base_url)
  set_line_edit_text(self.model_input, provider.model)
  set_line_edit_text(self.api_key_input, provider.api_key)
  self.status_label.setText(provider_status_text(provider))
  self.confirm_button.setEnabled(true)
  self.remove_button.setEnabled(providers.length() > 1)
}

///|
fn SettingsDialog::update_selected_provider_name(
  self : Self,
  text : String,
) -> Unit raise NullptrError {
  self.update_selected_provider(provider => ProviderConfig::{
    id: provider.id,
    name: text,
    kind: provider.kind,
    base_url: provider.base_url,
    api_key: provider.api_key,
    model: provider.model,
  })
}

///|
fn SettingsDialog::update_selected_provider_base_url(
  self : Self,
  text : String,
) -> Unit raise NullptrError {
  self.update_selected_provider(provider => ProviderConfig::{
    id: provider.id,
    name: provider.name,
    kind: provider.kind,
    base_url: text,
    api_key: provider.api_key,
    model: provider.model,
  })
}

///|
fn SettingsDialog::update_selected_provider_model(
  self : Self,
  text : String,
) -> Unit raise NullptrError {
  self.update_selected_provider(provider => ProviderConfig::{
    id: provider.id,
    name: provider.name,
    kind: provider.kind,
    base_url: provider.base_url,
    api_key: provider.api_key,
    model: text,
  })
}

///|
fn SettingsDialog::update_selected_provider_api_key(
  self : Self,
  text : String,
) -> Unit raise NullptrError {
  self.update_selected_provider(provider => ProviderConfig::{
    id: provider.id,
    name: provider.name,
    kind: provider.kind,
    base_url: provider.base_url,
    api_key: text,
    model: provider.model,
  })
}

///|
fn SettingsDialog::update_selected_provider(
  self : Self,
  update : (ProviderConfig) -> ProviderConfig,
) -> Unit raise NullptrError {
  let index = self.provider_select.currentIndex()
  let providers = self.providers_store.providers()
  guard index >= 0 && index < providers.length() else { () }

  let updated = update(providers[index])
  providers[index] = updated
  self.providers_store.set_providers(providers, Some(updated.id))
  self.reload_provider_select()
  self.provider_select.setCurrentIndex(index)
  self.status_label.setText(provider_status_text(updated))
}

///|
fn SettingsDialog::add_provider(self : Self) -> Unit raise NullptrError {
  let providers = self.providers_store.providers()
  let next_index = providers.length() + 1
  let provider = ProviderConfig::{
    id: next_provider_id(providers, next_index),
    name: "Provider \{next_index}",
    kind: OpenAICompatible,
    base_url: "https://api.openai.com/v1/chat/completions",
    api_key: "",
    model: "gpt-4.1-mini",
  }
  providers.push(provider)
  self.providers_store.set_providers(providers, Some(provider.id))
  self.reload_provider_select()
  self.provider_select.setCurrentIndex(self.provider_select.count() - 1)
  self.sync_editor_for_index(self.provider_select.currentIndex())
}

///|
fn SettingsDialog::remove_selected_provider(
  self : Self,
) -> Unit raise NullptrError {
  let index = self.provider_select.currentIndex()
  let providers = self.providers_store.providers()
  guard providers.length() > 1 else {
    self.status_label.setText("至少保留一个 provider。")
    ()
  }
  guard index >= 0 && index < providers.length() else { () }

  ignore(providers.remove(index))
  let next_index = index.min(providers.length() - 1)
  self.providers_store.set_providers(providers, Some(providers[next_index].id))
  self.reload_provider_select()
  self.provider_select.setCurrentIndex(next_index)
  self.sync_editor_for_index(next_index)
}

///|
fn SettingsDialog::accept_if_valid(self : Self) -> Unit raise NullptrError {
  let providers = self.providers_store.providers()
  guard providers.length() > 0 else {
    self.status_label.setText("请至少保留一个 provider。")
    ()
  }

  for provider in providers {
    match validate_provider(provider) {
      Some(message) => {
        self.status_label.setText(message)
        return
      }
      None => ()
    }
  }

  self.root.accept()
}

///|
fn validate_provider(provider : ProviderConfig) -> String? {
  if provider.name.trim().is_blank() {
    Some("Provider 显示名称不能为空。")
  } else if provider.base_url.trim().is_blank() {
    Some("Provider Base URL 不能为空。")
  } else if provider.model.trim().is_blank() {
    Some("Provider Model 不能为空。")
  } else {
    None
  }
}

///|
fn provider_option_label(provider : ProviderConfig) -> String {
  let name = if provider.name.trim().is_blank() {
    provider.id
  } else {
    provider.name.trim().to_string()
  }
  let model = provider.model.trim().to_string()
  if model.is_blank() {
    name
  } else {
    "\{name} · \{model}"
  }
}

///|
fn provider_status_text(provider : ProviderConfig) -> String {
  let key_text = if provider.api_key.trim().is_blank() {
    "未填写 API Key"
  } else {
    "API Key 已填写"
  }
  "ID: \{provider.id} · \{key_text}"
}

///|
fn next_provider_id(providers : Array[ProviderConfig], seed : Int) -> String {
  let mut index = seed.max(1)
  while true {
    let candidate = "provider-\{index}"
    if providers.all(provider => provider.id != candidate) {
      return candidate
    }
    index += 1
  }
  "provider-\{seed.max(1)}"
}

///|
fn settings_field_label(text : String) -> QLabel {
  try! ({
    let label = QLabel::new()
    label.setObjectName("SettingsFieldLabel")
    label.setText(text)
    label
  })
}

///|
fn set_line_edit_text(
  input : QLineEdit,
  text : String,
) -> Unit raise NullptrError {
  let blocked = input.blockSignals(true)
  input.setText(text)
  let _ = input.blockSignals(blocked)
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
