use std::cell::RefCell;
use std::ptr;
use std::rc::Rc;

use libc::{MAP_ANON, MAP_PRIVATE, mmap, PROT_READ, PROT_WRITE, size_t};

use crate::repetition_tester::repetition_tester::RepetitionTester;

struct TestParams {
    file_name: &'static str,
    expected_bytes: u64,
    seconds_to_try: u64,
    buffer: *mut u8,
}

fn write_all_bytes(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        for i in 0..total_size {
            unsafe {
                buffer[i] = i as u8;
            }
        }
        // while i < total_size {
        //     unsafe {
        //         buffer[i] = i as u8;
        //     }
        //     i += 1;
        // }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

pub fn run() {
    let total_size = 1024 * 1024 * 1024;
    let addr = unsafe {
        mmap(
            ptr::null_mut(),   // Address at which to start the mapping (nullptr lets the OS choose)
            total_size,        // Number of bytes to map
            PROT_READ | PROT_WRITE, // Enable read and write access
            MAP_PRIVATE | MAP_ANON,
            -1,                // File descriptor not used with MAP_ANON
            0,                 // Offset not used with MAP_ANON
        )
    };

    let params = TestParams {
        file_name: "test_file",
        expected_bytes: total_size as u64,
        seconds_to_try: 2,
        buffer: addr as *mut u8,
    };

    let testers = vec![
        Rc::new(RefCell::new(RepetitionTester::new())),
    ];

    let mut test_functions: Vec<(&str, Box<dyn FnMut()>)> = vec![
        (
            "Write All Bytes Test",
            Box::new({
                let tester = Rc::clone(&testers[0]);
                let params = &params;
                move || {
                    write_all_bytes(&mut *tester.borrow_mut(), params);
                }
            }),
        ),
    ];

    loop {
        for (test_name, test_function) in test_functions.iter_mut() {
            println!("\n----- {} -----", test_name);
            test_function();
        }
    }
}
