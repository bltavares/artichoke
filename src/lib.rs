use html5ever::serialize;
use kuchiki::traits::*;
use serde::Serialize;
use std::fs;

#[derive(Debug, Eq, PartialEq)]
pub struct Article {
    pub body: String,
    pub metadata: Metadata,
}

#[derive(Debug, Eq, PartialEq, Serialize)]
pub struct Metadata {
    pub title: Option<String>,
    pub author: Option<String>,
    pub date: Option<String>,
}

type Node = kuchiki::NodeDataRef<kuchiki::ElementData>;

fn to_dom(html: &str) -> kuchiki::NodeRef {
    kuchiki::parse_html().one(html)
}

fn render(elements: Node) -> String {
    let mut html = vec![];
    serialize::serialize(
        &mut html,
        elements.as_node(),
        serialize::SerializeOpts {
            scripting_enabled: false,
            create_missing_parent: true,
            traversal_scope: serialize::TraversalScope::IncludeNode,
        },
    )
    .expect("could not encode element");
    html2md::parse_html(&String::from_utf8_lossy(&html))
}

fn extract_hentry(document: kuchiki::NodeRef) -> Option<Node> {
    let mut entries = document
        .select(".h-entry, .entry, .hentry, .post")
        .ok()
        .unwrap();
    entries.next()
}

fn extract_hentry_content(entry: Node) -> Option<String> {
    let mut entries = entry
        .as_node()
        .select(".entry-content, .content, .post")
        .ok()
        .unwrap();
    let first_element = entries.next();

    first_element.map(render)
}

fn extract_metadata(dom: kuchiki::NodeRef) -> Metadata {
    let title: Option<Node> = dom.select("title").ok().unwrap().next();
    let title = title.map(|t| t.text_contents());
    Metadata {
        author: None,
        title,
        date: None,
    }
}

pub fn parse(html: &str) -> Option<Article> {
    let document = to_dom(html);
    let body = extract_hentry(document.clone()).and_then(extract_hentry_content)?;
    let metadata = extract_metadata(document);
    Some(Article { body, metadata })
}

pub fn frontmatter(article: Article) -> String {
    let metadata =
        toml::to_string_pretty(&article.metadata).expect("Invalid frontmatter toml data");
    format!("+++\n{}+++\n\n{}", metadata, article.body)
}

pub fn fetch_info(path: &str) -> String {
    if path.starts_with("http://") || path.starts_with("https://") {
        ureq::get(path)
            .call()
            .into_string()
            .expect("could not read http body")
    } else {
        fs::read_to_string(path).expect("could not read the local file")
    }
}
