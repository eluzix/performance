use std::error::Error;
use std::fs::File;
use std::io::{BufReader, Read};
use std::mem;

use crate::listing_0065_haversine_formula::reference_haversine;
use crate::naive_profiler;

type JsonValue = f64;

#[derive(PartialEq)]
enum State {
    Reading,
    ObjectStart,
    ObjectEnd,
    Key,
    Value,
}

#[derive(Debug)]
struct JsonObject {
    x0: JsonValue,
    y0: JsonValue,
    x1: JsonValue,
    y1: JsonValue,
}

impl JsonObject {
    fn reset(&mut self) {
        self.x0 = 0.0;
        self.y0 = 0.0;
        self.x1 = 0.0;
        self.y1 = 0.0;
    }

    fn set_val(&mut self, key: &str, val: JsonValue) {
        // let start = naive_profiler::start_span("set_val");
        match key {
            "x0" => self.x0 = val,
            "y0" => self.y0 = val,
            "x1" => self.x1 = val,
            "y1" => self.y1 = val,
            _ => {}
        }
        // naive_profiler::stop_span(start, 0);
    }

    fn clone(&self) -> Self {
        JsonObject {
            x0: self.x0,
            y0: self.y0,
            x1: self.x1,
            y1: self.y1,
        }
    }
}

struct JsonArray {
    objects: Vec<JsonObject>,
}

struct ParsingData {
    obj: JsonObject,
    state: State,
    key: String,
    val: String,
}

// #[derive(Debug)]
// struct TimePoint {
//     time: Duration,
//     label: String,
// }
//
// impl TimePoint {
//     fn new(time: Duration, label: &str) -> Self {
//         TimePoint { time, label: label.to_string()}
//     }
// }

impl ParsingData {
    fn new() -> Self {
        ParsingData {
            obj: JsonObject {
                x0: 0.0,
                y0: 0.0,
                x1: 0.0,
                y1: 0.0,
            },
            state: State::Reading,
            key: String::new(),
            val: String::new(),
        }
    }

    fn reset(&mut self) {
        self.obj.reset();
        self.state = State::ObjectEnd;
        self.key.clear();
        self.val.clear();
    }

    fn add_value(&mut self, char: char) {
        match self.state {
            State::Key => {
                self.key.push(char);
            }
            State::Value => {
                self.val.push(char);
            }
            _ => {}
        }
    }

    fn update_obj(&mut self) {
        if self.key.len() == 0 || self.val.len() == 0 {
            return;
        }

        let val = self.val.parse::<f64>().unwrap();
        self.obj.set_val(self.key.as_str(), val);
        self.key.clear();
        self.val.clear();
    }
}

pub fn parse(input_file: &str, validate: bool) -> Result<(), Box<dyn Error>> {
    naive_profiler::start_profiling();

    // let start = naive_profiler::start_span();
    // init a Duration vector with 5 places
    // let mut cpu_time: Duration = start.try_elapsed().expect("Getting process time failed");;
    // println!(" {:?}", cpu_time);

    let init_start = naive_profiler::start_span("Init");

    let f = File::open(input_file)?;
    let file_size = f.metadata().unwrap().len();
    println!("File size: {}", file_size);
    let mut reader = BufReader::new(f);

    // const BUFFER_SIZE: usize = 8096;
    const BUFFER_SIZE: usize = 1024 * 1024 * 4;
    let mut buffer = [0_u8; BUFFER_SIZE];
    let mut json_array = JsonArray {
        // objects: Vec::new(),
        objects: Vec::with_capacity(10000000),
    };
    let mut array_found = false;

    let mut parse_data = ParsingData::new();
    naive_profiler::stop_span(init_start, 0);

    let parse_start = naive_profiler::start_span("Parse");
    loop {
        let start = naive_profiler::start_span("Read");
        let count = reader.read(&mut buffer)?;
        naive_profiler::stop_span(start, count as u64);
        // if count == 0 || json_array.objects.len() > 10 {
        if count == 0 {
            break;
        }

        let start = naive_profiler::start_span("Loop");
        let string_slice = std::str::from_utf8(&buffer[..count])?;

        for char in string_slice.chars() {
            if !array_found {
                if char == '[' {
                    array_found = true;
                }

                continue;
            }

            match char {
                '[' | ']' | ',' | ':' => {}
                ' ' | '\n' | '\t' => {}
                '{' => {
                    parse_data.state = State::ObjectStart;
                }
                '}' => {
                    // Do something
                    let start_update = naive_profiler::start_span("Update");
                    parse_data.update_obj();
                    json_array.objects.push(parse_data.obj.clone());
                    parse_data.reset();
                    naive_profiler::stop_span(start_update, 0);
                }
                '"' => {
                    let state_update = naive_profiler::start_span("State");
                    if parse_data.key.len() == 0 {
                        parse_data.state = State::Key;
                    } else if parse_data.state == State::Key {
                        parse_data.state = State::Value;
                    } else if parse_data.state == State::Value {
                        parse_data.state = State::Key;
                        parse_data.update_obj();
                    }
                    naive_profiler::stop_span(state_update, 0);
                }

                _ => {
                    parse_data.add_value(char);
                }
            }
        }
        naive_profiler::stop_span(start, count as u64);
    }

    // delete the last object in json_array.objects
    json_array.objects.pop();
    naive_profiler::stop_span(parse_start, 0);

    if validate {
        let start_validate = naive_profiler::start_span("Validate");
        let validate_start = naive_profiler::start_span("Validate Read");
        let binary_file_name = format!("{}.bin", input_file);
        let mut verify_file = File::open(binary_file_name)?;
        let mut buffer = Vec::new();
        verify_file.read_to_end(&mut buffer)?;

        let buffer_size = buffer.len();
        naive_profiler::stop_span(validate_start, buffer_size as u64);

        let validate_start = naive_profiler::start_span("Validate parse");
        let chunk_size = mem::size_of::<f64>();
        for (i, chunk) in buffer.chunks(chunk_size).enumerate() {
            if i == json_array.objects.len() {
                break;
            }

            if chunk.len() == chunk_size {
                // Correctly slice each part of the chunk for individual f64 values
                let distance_bytes: [u8; 8] = chunk[0..8].try_into()?;
                let distance = f64::from_be_bytes(distance_bytes);

                let obj = &json_array.objects[i];
                let haversine_start = naive_profiler::start_span("Haversine");
                let haversine_distance = reference_haversine(obj.x0, obj.y0, obj.x1, obj.y1);
                if (distance - haversine_distance).abs() > 0.0000001 {
                    println!(
                        "Mismatch found in chunk {}: distance: {} vs haversine_distance: {}",
                        i, distance, haversine_distance
                    );
                }
                naive_profiler::stop_span(haversine_start, distance_bytes.len() as u64);
            }
        }
        naive_profiler::stop_span(validate_start, 0);
        naive_profiler::stop_span(start_validate, buffer_size as u64);
    }

    // for obj in json_array.objects.iter() {
    //     println!("{:?}", obj);
    // }
    // naive_profiler::stop_span(start, "all");
    naive_profiler::stop_profiling();
    naive_profiler::report();

    // let total_time = start.elapsed();
    // for i in 0..vec.len() - 1 {
    //     let time = vec[i + 1].time - vec[i].time;
    //     println!("{}: {:?}", vec[i+1].label, time);
    // }
    // println!("Total time: {:?}", total_time);
    // println!("{:?}", vec);
    println!("Total objects: {}", json_array.objects.len());

    Ok(())
}
