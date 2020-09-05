use clap::{App, Arg};

fn main() {
    env_logger::init();

    let matches = App::new("artichoke")
        .arg(Arg::with_name("path").required(true))
        .get_matches();
    let path = matches.value_of("path").unwrap();

    let output = {
        let content = artichoke::fetch_info(path);
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
