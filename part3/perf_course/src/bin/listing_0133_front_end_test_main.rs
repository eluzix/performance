extern crate perf_course;

use std::cell::RefCell;
use std::error::Error;
use std::ptr;
use std::rc::Rc;

use libc::{MAP_ANON, MAP_PRIVATE, mmap, PROT_READ, PROT_WRITE, size_t};

use perf_course::repetition_tester::repetition_tester::RepetitionTester;

extern "C" {
    fn GarbageLoopExample(count: u64, data: *mut u8);
    fn FullLoopExample(count: u64, data: *mut u8);
    fn NopLoopExample(count: u64);
    fn JustLoopExample(count: u64);
    fn DecLoopExample(count: u64);
}

struct TestParams {
    // file_name: &'static str,
    expected_bytes: u64,
    seconds_to_try: u64,
    buffer: *mut u8,
}

struct TesterFunction {
    name: &'static str,
    function: fn(&mut RepetitionTester, &TestParams),
    tester: Rc<RefCell<RepetitionTester>>,
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
        // }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

fn garbage_loop_example(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        unsafe {
            GarbageLoopExample(total_size as u64, buffer.as_mut_ptr());
        }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

fn write_full_loop_example(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        unsafe {
            FullLoopExample(total_size as u64, buffer.as_mut_ptr());
        }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

fn nop_loop_example(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        unsafe {
            NopLoopExample(total_size as u64);
        }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

fn just_loop_example(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        unsafe {
            JustLoopExample(total_size as u64);
        }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
}

fn dec_loop_example(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let total_size = params.expected_bytes as size_t;
    // let buffer = params.buffer;
    let buffer = unsafe { std::slice::from_raw_parts_mut(params.buffer, total_size) };
    while tester.is_testing() {
        let mut i = 0;
        tester.begin_time();
        unsafe {
            DecLoopExample(total_size as u64);
        }
        tester.end_time();

        tester.count_bytes(total_size as u64);
    }
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

    let mut functions = vec![
        TesterFunction {
            name: "Write All Bytes Test",
            function: write_all_bytes,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "FullLoopExample Test",
            function: write_full_loop_example,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "GarbageLoopExample Test",
            function: garbage_loop_example,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "NopLoopExample Test",
            function: nop_loop_example,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "JustLoopExample Test",
            function: just_loop_example,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "DecLoopExample Test",
            function: dec_loop_example,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
    ];

    let params = TestParams {
        expected_bytes: total_size as u64,
        seconds_to_try: 2,
        buffer: addr as *mut u8,
    };

    loop {
        for ft in &functions {
            println!("\n----- {} -----", ft.name);
            (ft.function)(
                &mut ft.tester.borrow_mut(),
                &params,
            );
        }
    }
}