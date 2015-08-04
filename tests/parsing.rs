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
              This should be your article.
          </article>
        </body>
    </html>
    ";

   let result = artichoke::parse(&example);
   assert_eq!(result, Some(Article { body = "This should be your article." }));
}
