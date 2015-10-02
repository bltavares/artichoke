extern crate kuchiki;

use kuchiki::Html;

#[derive(Debug, Eq, PartialEq)]
pub struct Article {
    pub body: String
}

fn to_dom(html: &str) -> kuchiki::NodeRef {
    Html::from_string(html).parse()
}

fn render(entry: kuchiki::iter::Select<kuchiki::iter::Elements<kuchiki::iter::Descendants>>) -> Option<Article> {
    let mut buffer = String::new();

    for elements in entry {
        for text_node in elements.as_node().descendants() {
            match text_node.as_text() {
                Some(text_node) => {
                    let text = &*text_node.borrow();
                    let words = text.split_whitespace()
                        .collect::<Vec<_>>()
                        .connect(" ");
                    buffer.push_str(&words);

                    if !words.is_empty() {
                        buffer.push_str("\n");
                    }
                },
                None => ()
            }
        }
    }

    if buffer.is_empty() {
        None
    } else {
        Some(Article { body: buffer })
    }
}

pub fn parse(html: &str) -> Option<Article> {
    let document = to_dom(html);
    document.select(".h-entry")
        .ok()
        .and_then(render)
}
