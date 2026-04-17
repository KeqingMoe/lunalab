///|
pub(all) enum Role {
  System
  User
  Assistant
} derive(FromJson, ToJson, Eq, Debug)

///|
pub impl Show for Role with output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub(all) struct Message {
  role : Role
  content : String
} derive(FromJson, ToJson, Eq, Debug)

///|
pub impl Show for Message with output(self, logger) {
  logger.write_string(@debug.to_string(self))
}

///|
pub fn Message::system(content : String) -> Self {
  Message::{ role: System, content }
}

///|
pub fn Message::user(content : String) -> Self {
  Message::{ role: User, content }
}

///|
pub fn Message::assistant(content : String) -> Self {
  Message::{ role: Assistant, content }
}
