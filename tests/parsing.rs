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
              <p>This should be your article.</p>
          </article>
        </body>
    </html>
    ";

   let result = artichoke::parse(&example);
   assert_eq!(result, Some(artichoke::Article { body : "This should be your article.".to_owned() }));
}
