use std::env;
use std::error::Error;
// use std::io::prelude::*;

use json_parser::parse;

mod json_parser;
mod listing_0065_haversine_formula;
mod json_generator;
mod naive_profiler;

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();

    // check for 2 different options: generate and parse each get a file path as an argument
    if args.len() < 3 {
        eprintln!("Usage: {} generate|parse <file>", args[0]);
        std::process::exit(1);
    }

    match &args[1][..] {
        "generate" => {
            if args.len() < 4 {
                eprintln!("Usage: {} generate <file> <count> [cluster|uniform] [seed]", args[0]);
                std::process::exit(1);
            }

            let count = args[3].parse::<usize>().expect("Invalid count");
            // grab the method and seed if they are provided or provide defaults
            let method = args.get(4).map(|s| s.to_string()).unwrap_or("uniform".to_string());
            let seed = args.get(5).map(|s| s.parse::<u64>().expect("Invalid seed")).unwrap_or(0);

            println!("Generating data with count {} and method {:?}", count, method);
            let _ = json_generator::generate_json(&method, count, seed, &args[2]);
        }

        "parse" => {
            let verify = args.get(3).map(|s| s == "true").unwrap_or(false);
            parse(&args[2], verify)?;
        }
        _ => {
            panic!("Invalid option");
        }
    }


    Ok(())
}
