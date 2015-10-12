extern crate artichoke;

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
    assert_eq!(result,
               Some(artichoke::Article {
                   body: "This should be your article.\nWith this being a new line.\n".to_owned(),
                   author: None,
                   date: None,
                   title: None,
               }));
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
