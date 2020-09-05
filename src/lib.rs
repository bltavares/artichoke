use html5ever::serialize;
use kuchiki::traits::*;
use serde::Serialize;
use std::{fs, time::Duration};

macro_rules! debug_extraction {
    ( $method:expr, $x:expr ) => {{
        let extraction = $x;
        log::debug!("attempting {} extraction: {:?}", $method, &extraction);
        extraction
    }};
}

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
    pub word_count: usize,
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
    html2md::parse_html(&String::from_utf8(html).expect("could not read page as utf8"))
}

fn extract_hentry(document: &kuchiki::NodeRef) -> Option<String> {
    let mut entries = document
        .select(".h-entry, .entry, .hentry, .post")
        .ok()
        .unwrap();

    debug_extraction!("h-entry", entries.next().and_then(extract_hentry_content))
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

fn extract_generic_article(document: &kuchiki::NodeRef) -> Option<String> {
    let mut entries = document
        .select(".article-body, .page-body, .content, article, #post, main")
        .ok()
        .unwrap();
    debug_extraction!("article", entries.next().map(render))
}

fn extract_amp(document: &kuchiki::NodeRef) -> Option<String> {
    let mut entries = document.select(".article-description").ok().unwrap();
    debug_extraction!("amp", entries.next().map(render))
}

fn extract_metadata(dom: kuchiki::NodeRef, body: &str) -> Metadata {
    let title: Option<Node> = dom.select("title").ok().unwrap().next();
    let title = title.map(|t| t.text_contents());
    Metadata {
        author: None,
        title,
        date: None,
        word_count: body.split_whitespace().count(),
    }
}

pub fn parse(html: &str) -> Option<Article> {
    let document = to_dom(html);
    let body = None
        .or_else(|| extract_hentry(&document))
        .or_else(|| extract_amp(&document))
        .or_else(|| extract_generic_article(&document))?;
    let metadata = extract_metadata(document, &body);
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
            .redirects(5)
            .timeout(Duration::from_secs(5))
            .call()
            .into_string()
            .expect("could not read http body")
    } else {
        fs::read_to_string(path).expect("could not read the local file")
    }
}
