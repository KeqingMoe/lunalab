///|
fn app_state_dir() -> String {
  ".lunalab"
}

///|
fn app_state_path() -> String {
  app_state_dir() + "/state.json"
}

///|
pub fn load_app_state_snapshot() -> AppStateSnapshot {
  if !@fs.path_exists(app_state_path()) {
    return default_app_state_snapshot()
  }

  let file_result : Result[String, _] = try? @fs.read_file_to_string(
    app_state_path(),
  )
  match file_result {
    Ok(content) => decode_app_state_snapshot(content)
    Err(_) => default_app_state_snapshot()
  }
}

///|
pub fn save_app_state_snapshot(snapshot : AppStateSnapshot) -> Unit {
  let content = sanitize_snapshot(snapshot).to_json().stringify(indent=2)
  if !@fs.path_exists(app_state_dir()) {
    ignore(try? @fs.create_dir(app_state_dir()))
  }
  ignore(try? @fs.write_string_to_file(app_state_path(), content))
}

///|
fn decode_app_state_snapshot(content : String) -> AppStateSnapshot {
  let json_result : Result[Json, _] = try? @json.parse(content)
  match json_result {
    Ok(json) => {
      let snapshot_result : Result[AppStateSnapshot, _] = try? @json.from_json(
        json,
      )
      match snapshot_result {
        Ok(snapshot) => sanitize_snapshot(snapshot)
        Err(_) => default_app_state_snapshot()
      }
    }
    Err(_) => default_app_state_snapshot()
  }
}
