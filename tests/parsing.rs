use artichoke;

#[test]
fn extracts_h_articles() {
    let example = "
    <html>
        <head>
          <title>A Title</title>
        </head>
        <body>
          <article class='h-entry'>
              <div class='entry-content'>
                  <p>This should be your article.</p>
                   <p>With this being a new line.</p>
              </div>
          </article>
        </body>
    </html>
    ";

    let result = artichoke::parse(&example);
    assert_eq!(
        result,
        Some(artichoke::Article {
            body: "This should be your article.\n\nWith this being a new line.".to_owned(),
            metadata: artichoke::Metadata {
                author: None,
                date: None,
                title: Some("A Title".into()),
                word_count: 11,
            }
        })
    );
}

#[test]
fn extracts_nothing() {
    let example = "
    <html>
        <head>
          <title>A Title</title>
        </head>
        <body>
        </body>
    </html>
    ";

    let result = artichoke::parse(&example);
    assert_eq!(result, None);
}
