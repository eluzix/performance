use std::env;
use std::error::Error;
use std::fs::File;
use std::io::BufReader;
use std::io::prelude::*;

use json_parser::parse;
use listing_0065_haversine_formula::reference_haversine;

mod json_parser;
mod listing_0065_haversine_formula;

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();

    // check for 2 different options: generate and parse each get a file path as an argument
    if args.len() < 3 {
        eprintln!("Usage: {} generate|parse <file>", args[0]);
        std::process::exit(1);
    }

    match &args[1][..] {
        "generate" => {
            println!("Generating data");
            let r = reference_haversine(-63.37, -1.72, 94.44429,12.4140);
            println!("Reference: {}", r);
        }

        "parse" => {
            println!("Parsing data");
            let f = File::open(&args[2])?;
            let reader = BufReader::new(f);
            parse(reader)?;
        }
        _ => {
            panic!("Invalid option");
        }
    }


    Ok(())
}
