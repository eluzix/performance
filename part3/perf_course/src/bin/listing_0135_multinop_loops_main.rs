extern crate perf_course;

use std::cell::RefCell;
use std::error::Error;
use std::ptr;
use std::rc::Rc;
use libc::{MAP_ANON, MAP_PRIVATE, mmap, PROT_READ, PROT_WRITE, size_t};

use perf_course::repetition_tester::repetition_tester::RepetitionTester;

extern "C" {
    fn NOP1AllBytes(count:u64, data: *mut u8);
    fn NOP3AllBytes(count:u64, data: *mut u8);
    fn NOP9AllBytes(count:u64, data: *mut u8);
}


fn main() -> Result<(), Box<dyn Error>> {
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

    let testers = vec![
        Rc::new(RefCell::new(RepetitionTester::new())),
        Rc::new(RefCell::new(RepetitionTester::new())),
        Rc::new(RefCell::new(RepetitionTester::new())),
    ];

    let seconds_to_try = 2;
    let expected_bytes = total_size as u64;

    let mut test_functions: Vec<(&str, Box<dyn FnMut()>)> = vec![
        (
            "NOP1AllBytes",
            Box::new({
                let tester = Rc::clone(&testers[0]);
                move || {
                    let mut tester = tester.borrow_mut();
                    tester.start_test_wave(seconds_to_try, expected_bytes);
                    let total_size = expected_bytes as size_t;
                    let buffer = unsafe { std::slice::from_raw_parts_mut(addr, total_size) };
                    while tester.is_testing() {
                        let mut i = 0;
                        tester.begin_time();
                        unsafe {
                            NOP1AllBytes(total_size as u64, buffer.as_mut_ptr() as *mut u8);
                        }
                        tester.end_time();

                        tester.count_bytes(total_size as u64);
                    }
                }
            }),
        ),
        (
            "NOP3AllBytes",
            Box::new({
                let tester = Rc::clone(&testers[1]);
                move || {
                    let mut tester = tester.borrow_mut();
                    tester.start_test_wave(seconds_to_try, expected_bytes);
                    let total_size = expected_bytes as size_t;
                    let buffer = unsafe { std::slice::from_raw_parts_mut(addr, total_size) };
                    while tester.is_testing() {
                        let mut i = 0;
                        tester.begin_time();
                        unsafe {
                            NOP3AllBytes(total_size as u64, buffer.as_mut_ptr() as *mut u8);
                        }
                        tester.end_time();

                        tester.count_bytes(total_size as u64);
                    }
                }
            }),
        ),
        (
            "NOP9AllBytes",
            Box::new({
                let tester = Rc::clone(&testers[2]);
                move || {
                    let mut tester = tester.borrow_mut();
                    tester.start_test_wave(seconds_to_try, expected_bytes);
                    let total_size = expected_bytes as size_t;
                    let buffer = unsafe { std::slice::from_raw_parts_mut(addr, total_size) };
                    while tester.is_testing() {
                        let mut i = 0;
                        tester.begin_time();
                        unsafe {
                            NOP9AllBytes(total_size as u64, buffer.as_mut_ptr() as *mut u8);
                        }
                        tester.end_time();

                        tester.count_bytes(total_size as u64);
                    }
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
