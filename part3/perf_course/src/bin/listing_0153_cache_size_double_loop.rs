extern crate perf_course;

use std::cell::RefCell;
use std::error::Error;
use std::ptr;
use std::rc::Rc;

use libc::{mmap, size_t, MAP_ANON, MAP_PRIVATE, PROT_READ, PROT_WRITE};

use perf_course::repetition_tester::repetition_tester::RepetitionTester;

extern "C" {
    fn ReadBufferDoubleLoopTest(outer_loop_count: u64, data: *mut u8, inner_loop_count: u64);
}

struct TestParams {
    expected_bytes: u64,
    seconds_to_try: u64,
    buffer: *mut u8,
}

struct TesterFunction {
    name: &'static str,
    read_size: u64,
    chunk_count: u64,
    function: unsafe extern "C" fn(outer_loop_count: u64, data: *mut u8, inner_loop_count: u64),
    tester: Rc<RefCell<RepetitionTester>>,
}

impl TesterFunction {
    fn new(
        name: &'static str,
        read_size: u64,
        total_size: usize,
        function: unsafe extern "C" fn(outer_loop_count: u64, data: *mut u8, inner_loop_count: u64),
    ) -> Self {
        let chunk_count = total_size as u64 / read_size;

        println!(
            "For {} read_size: {} chunk_count: {}",
            name, read_size, chunk_count
        );

        TesterFunction {
            name,
            read_size,
            chunk_count: chunk_count as u64,
            function,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let total_size = 1024 * 1024 * 1024;
    let addr = unsafe {
        mmap(
            ptr::null_mut(), // Address at which to start the mapping (nullptr lets the OS choose)
            total_size,      // Number of bytes to map
            PROT_READ | PROT_WRITE, // Enable read and write access
            MAP_PRIVATE | MAP_ANON,
            -1, // File descriptor not used with MAP_ANON
            0,  // Offset not used with MAP_ANON
        )
    };

    let functions = vec![
        // TesterFunction::new(
        //     "Double Loop 16Kb",
        //     1024 * 16,
        //     total_size,
        //     ReadBufferDoubleLoopTest,
        // ),
        //
        // TesterFunction::new(
        //     "Double Loop 96Kb",
        //     1024 * 96,
        //     total_size,
        //     ReadBufferDoubleLoopTest,
        // ),
        TesterFunction::new(
            "Double Loop 96Kb",
            1024 * 96,
            total_size,
            ReadBufferDoubleLoopTest,
        ),
        TesterFunction::new(
            "Double Loop 160Kb",
            1024 * 160,
            total_size,
            ReadBufferDoubleLoopTest,
        ),
        TesterFunction::new(
            "Double Loop 200Kb",
            1024 * 200,
            total_size,
            ReadBufferDoubleLoopTest,
        ),
    ];

    let params = TestParams {
        expected_bytes: total_size as u64,
        seconds_to_try: 2,
        buffer: addr as *mut u8,
    };

    let buffer = unsafe { std::slice::from_raw_parts_mut(addr as *mut u8, total_size) };
    unsafe {
        for i in 0..total_size {
            buffer[i] = i as u8;
        }
    }

    loop {
        for ft in &functions {
            println!("\n----- {} -----", ft.name);
            let mut tester = ft.tester.borrow_mut();
            tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
            let total_size = params.expected_bytes as size_t;
            while tester.is_testing() {
                tester.begin_time();
                unsafe {
                    (ft.function)(ft.chunk_count, buffer.as_mut_ptr() as *mut u8, ft.read_size);
                }
                tester.end_time();
                tester.count_bytes(total_size as u64);
            }
        }
    }
}
