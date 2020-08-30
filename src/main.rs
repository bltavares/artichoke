use clap::{App, Arg};
use std::fs;

fn fetch_info(path: &str) -> String {
    if path.starts_with("http://") || path.starts_with("https://") {
        ureq::get(path)
            .call()
            .into_string()
            .expect("could not read http body")
    } else {
        fs::read_to_string(path).expect("could not read the local file")
    }
}

fn main() {
    let matches = App::new("artichoke")
        .arg(Arg::with_name("path").required(true))
        .get_matches();

    let output = {
        let content = fetch_info(matches.value_of("path").unwrap());
        artichoke::parse(&content).map(artichoke::frontmatter)
    };

    match output {
        Some(content) => println!("{}", content),
        None => {
            println!("No article view from the given path");
            std::process::exit(1);
        }
    }
}
