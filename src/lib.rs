#[derive(Debug, Eq, PartialEq)]
pub struct Article {
    pub body: String
}

pub fn parse(html: &str) -> Option<Article> {
    Some(Article { body: "This should be your article.".to_owned() })
}
