use std::io::Write;
use rand::distributions::{Distribution, Uniform};
use rand::thread_rng;
use rand::Rng;
use rand::SeedableRng;

use crate::listing_0065_haversine_formula::reference_haversine;

// a function that gets a point and a range and returns a random number within that range
fn random_in_range(x0: (f64, f64), y0: (f64, f64), x1: (f64, f64), y1: (f64, f64)) -> (f64, f64, f64, f64) {
    let mut rng = thread_rng();

    // Correctly create a uniform distribution for each range
    let dist_x0 = Uniform::new_inclusive(x0.0, x0.1);
    let dist_y0 = Uniform::new_inclusive(y0.0, y0.1);
    let dist_x1 = Uniform::new_inclusive(x1.0, x1.1);
    let dist_y1 = Uniform::new_inclusive(y1.0, y1.1);

    // Generate a random value within each range
    let rand_x0 = dist_x0.sample(&mut rng);
    let rand_y0 = dist_y0.sample(&mut rng);
    let rand_x1 = dist_x1.sample(&mut rng);
    let rand_y1 = dist_y1.sample(&mut rng);

    (rand_x0, rand_y0, rand_x1, rand_y1)
}

fn point_for_range(start: f64, end: f64) -> (f64, f64){
    let mut rng = thread_rng();
    let point = rng.gen_range(start..=end);
    // range starting from point till range end's
    (point, rng.gen_range(point..=end))
}

pub fn generate_json(method: &str, count: usize, seed: u64, output_file: &str) -> Result<(), std::io::Error>{
    let mut ranges;

    // set the seed
    rand::rngs::StdRng::seed_from_u64(seed);

    if method == "uniform" {
        ranges = vec![(-180.0, 180.0), (-90.0, 90.0), (-180.0, 180.0), (-90.0, 90.0)];
    } else {
        let mut rng = thread_rng();
        let num_clusters = rng.gen_range(3..=10);
        println!("Generating data with {} clusters", num_clusters);
        ranges = Vec::new();
        for _ in 0..num_clusters {
            let x0 = point_for_range(-180.0, 180.0);
            let y0 = point_for_range(-90.0, 90.0);
            let x1 = point_for_range(-180.0, 180.0);
            let y1 = point_for_range(-90.0, 90.0);
            ranges.push(x0);
            ranges.push(x1);
            ranges.push(y0);
            ranges.push(y1);
        }
    }

    // open file for write
    let binary_file_name = format!("{}.bin", output_file);
    let mut binary_file = std::fs::File::create(binary_file_name).expect("Unable to create file");

    let mut file = std::fs::File::create(output_file).expect("Unable to create file");
    let mut line = format!("{{\"pairs\":[\n");
    file.write(line.as_bytes()).expect("Unable to write data to file");

    let sum_coefficient = 1.0 / count as f64;
    let mut total = 0.0;
    // loop through the count and generate random points
    for _ in 0..count {
        let (x0, y0, x1, y1) = random_in_range(ranges[0], ranges[1], ranges[2], ranges[3]);
        let distance = reference_haversine(x0, y0, x1, y1);

        // write to file
        let json_line = format!("{{\"x0\":{},\"y0\":{},\"x1\":{},\"y1\":{}}}\n", x0, y0, x1, y1);
        file.write_all(json_line.as_bytes())?;
        // write x0, y0, x1, y1 to binary file + new line
        binary_file.write_all(&distance.to_be_bytes())?;

        total += distance * sum_coefficient;
    }
    line = format!("]}}\n");
    file.write(line.as_bytes())?;
    binary_file.write_all(&total.to_be_bytes())?;

    println!("Generated {} points", count);
    println!("Seed: {}", seed);
    println!("Method: {}", method);
    println!("Total distance: {}", total);

    Ok(())
}
