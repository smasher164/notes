use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use automerge::Automerge;

#[derive(Serialize, Deserialize, Debug)]
#[serde(untagged)]
enum Operation {
    Insert {
        insert: String,

        #[serde(skip_serializing_if = "Option::is_none")]
        attributes: Option<HashMap<String, serde_json::Value>>,
    }, // TODO: data could be more than a String.

    Delete {
        delete: i64,
    },
    Retain {
        retain: i64,

        #[serde(skip_serializing_if = "Option::is_none")]
        attributes: Option<HashMap<String, serde_json::Value>>,
    },
}

#[derive(Serialize, Deserialize, Debug)]
struct Delta(Vec<Operation>);

pub fn print_json(data: String) {
    let deserialized: Delta = serde_json::from_str(&data).unwrap();
    println!("{:?}", deserialized);
}
