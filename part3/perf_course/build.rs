use std::env;

fn main() {

    match env::var("OBJ_FILE") {
        Ok(object_file) => {
            println!("cargo:rustc-link-arg={}", object_file);
        },
        Err(_) => {}
    }
    //
    // let object_file = env::var("OBJ_FILE").unwrap();
    // // println!("cargo:rustc-link-arg=listing_0132_nop_loop.o");
    // println!("cargo:rustc-link-arg={}", object_file);
}
