extern crate kuchiki;

use kuchiki::Html;

#[derive(Debug, Eq, PartialEq)]
pub struct Article {
    pub body: String,
    pub title: Option<String>,
    pub author: Option<String>,
    pub date: Option<String>,
}

type Node = kuchiki::NodeDataRef<kuchiki::ElementData>;

fn to_dom(html: &str) -> kuchiki::NodeRef {
    Html::from_string(html).parse()
}

fn render(elements: Node) -> String {
    let mut buffer = String::new();

    for text_node in elements.as_node().descendants() {
        match text_node.as_text() {
            Some(text_node) => {
                let text = &*text_node.borrow();
                let words = text.split_whitespace()
                                .collect::<Vec<_>>()
                                .join(" ");
                buffer.push_str(&words);

                if !words.is_empty() {
                    buffer.push_str("\n");
                }
            }
            None => (),
        }
    }

    buffer
}

fn extract_hentry(document: kuchiki::NodeRef) -> Option<Node> {
    let mut entries = document.select(".h-entry, .entry, .hentry").ok().unwrap();
    entries.next()
}

fn extract_hentry_content(entry: Node) -> Option<String> {
    let mut entries = entry.as_node().select(".entry-content, .content").ok().unwrap();
    let first_element = entries.next();

    first_element.map(render)
}

pub fn parse(html: &str) -> Option<Article> {
    let document = to_dom(html);
    extract_hentry(document)
        .and_then(|hentry| extract_hentry_content(hentry))
        .map(|x| {
            Article {
                body: x,
                author: None,
                date: None,
                title: None,
            }
        })
}
