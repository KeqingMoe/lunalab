///|
type ProviderRequestPayload = Bytes

///|
fn provider_missing_config_message(provider : ProviderConfig?) -> String? {
  match provider {
    None =>
      Some(
        "还没有可用的 provider。请先在设置中添加并选择一个 provider。",
      )
    Some(provider) =>
      if provider.base_url.trim().is_blank() {
        Some(
          "当前 provider 缺少请求地址。请在设置中补全 Base URL。",
        )
      } else if provider.model.trim().is_blank() {
        Some(
          "当前 provider 缺少模型名称。请在设置中补全 Model。",
        )
      } else if provider.api_key.trim().is_blank() {
        Some(
          "当前 provider 缺少 API Key。请在设置中填写后再发送消息。",
        )
      } else {
        None
      }
  }
}

///|
fn provider_request_url(provider : ProviderConfig) -> String {
  provider.base_url.trim().to_string()
}

///|
fn provider_auth_header_value(provider : ProviderConfig) -> Bytes {
  @utf8.encode("Bearer \{provider.api_key.trim().to_string()}")
}

///|
fn provider_failure_message(
  provider : ProviderConfig,
  status_code : Int,
  reason_phrase : String,
  error_string : String,
  raw_text : String,
) -> String {
  let provider_name = provider.name.trim().to_string()
  let parts = ["\{provider_name} 请求失败。"]
  if status_code > 0 {
    let status = if reason_phrase.trim().is_blank() {
      status_code.to_string()
    } else {
      "\{status_code} \{reason_phrase.trim().to_string()}"
    }
    parts.push("HTTP: \{status}")
  }
  if !error_string.trim().is_blank() {
    parts.push("错误: \{error_string.trim().to_string()}")
  }

  let detail = summarize_provider_error_payload(raw_text)
  if !detail.is_blank() {
    parts.push("详情: \{detail}")
  }
  parts.join("\n")
}

///|
fn summarize_provider_error_payload(raw_text : String) -> String {
  let parse_result : Result[Json, _] = try? @json.parse(raw_text)
  match parse_result {
    Ok(json) =>
      extract_error_message(json).unwrap_or(raw_text.trim().to_string())
    Err(_) => raw_text.trim().to_string()
  }
}

///|
fn extract_error_message(json : Json) -> String? {
  guard json is Object(root) else { None }
  match root.get("error") {
    Some(String(message)) => Some(message)
    Some(Object(error)) =>
      match error.get("message") {
        Some(String(message)) => Some(message)
        _ => None
      }
    _ => None
  }
}

///|
fn message_to_json(message : Message) -> Json {
  Json::object(
    Map::from_array([
      ("role", Json::string(provider_role_name(message.role))),
      ("content", Json::string(message.content)),
    ]),
  )
}

///|
fn provider_role_name(role : Role) -> String {
  match role {
    System => "system"
    User => "user"
    Assistant => "assistant"
  }
}

///|
struct SSEChunk {
  contents : Array[String]
  is_done : Bool
}

///|
pub fn build_provider_stream_request_body(
  provider : ProviderConfig,
  messages : Array[Message],
) -> ProviderRequestPayload {
  let body = Json::object(
    Map::from_array([
      ("model", Json::string(provider.model.trim().to_string())),
      ("messages", Json::array(messages.map(message_to_json))),
      ("stream", Json::boolean(true)),
    ]),
  ).stringify()
  @utf8.encode(body)
}

///|
pub fn parse_sse_chunk(buffer : String) -> (SSEChunk, String) {
  let lines = buffer.split("\n")
  let contents = []
  let mut is_done = false
  let mut remaining = ""

  for line in lines {
    let trimmed = line.trim().to_string()
    if trimmed.has_prefix("data: ") {
      let data = trimmed.replace(old="data: ", new="")
      if data == "[DONE]" {
        is_done = true
        continue
      }
      try @json.parse(data) catch {
        _ => remaining = remaining + line.to_string() + "\n"
      } noraise {
        json =>
          match extract_delta_content(json) {
            Some(content) => contents.push(content)
            None => ()
          }
      }
    } else if !trimmed.is_blank() {
      remaining = remaining + line.to_string() + "\n"
    }
  }

  (SSEChunk::{ contents, is_done }, remaining)
}

///|
fn extract_delta_content(json : Json) -> String? {
  guard json is Object(root) else { None }
  guard root.get("choices") is Some(Array(choices)) else { None }
  guard choices.length() > 0 else { None }
  guard choices[0] is Object(choice) else { None }
  guard choice.get("delta") is Some(Object(delta)) else { None }
  let content = match delta.get("content") {
    Some(String(text)) => text
    _ => ""
  }
  let reasoning = match delta.get("reasoning") {
    Some(String(text)) => text
    _ => ""
  }
  let combined = content + reasoning
  if combined.is_blank() {
    None
  } else {
    Some(combined)
  }
}
