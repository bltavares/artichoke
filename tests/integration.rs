use std::fs;
use std::path::Path;
use test_generator::test_resources;

use artichoke;

#[test_resources("tests/resources/html/*.html")]
fn verify_template(resource: &str) {
    let html = Path::new(resource);
    let origin = fs::read_to_string(html).expect("failed to read origin file");

    let markdown = format!(
        "tests/resources/md/{}.md",
        html.file_stem().unwrap().to_string_lossy()
    );
    let markdown = Path::new(&markdown);
    let expected = fs::read_to_string(markdown).expect("failed to read expected file");

    // fs::write(
    //     markdown,
    //     artichoke::parse(&origin)
    //         .map(artichoke::frontmatter)
    //         .unwrap(),
    // ).expect("failed to write new files");

    assert_eq!(
        artichoke::parse(&origin)
            .map(artichoke::frontmatter)
            .unwrap(),
        expected
    );
}
