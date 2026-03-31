///|
pub(all) enum Role {
  System
  User
  Assistant
} derive(FromJson, ToJson, Eq, Show)

///|
pub(all) struct Message {
  role : Role
  content : String
} derive(FromJson, ToJson, Eq, Show)

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
