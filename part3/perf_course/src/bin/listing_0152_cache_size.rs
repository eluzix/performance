extern crate perf_course;

use std::cell::RefCell;
use std::error::Error;
use std::ptr;
use std::rc::Rc;

use libc::{mmap, size_t, MAP_ANON, MAP_PRIVATE, PROT_READ, PROT_WRITE};

use perf_course::repetition_tester::repetition_tester::RepetitionTester;

extern "C" {
    fn ReadBufferTest(count: u64, data: *mut u8, mask: u64);
}

struct TestParams {
    expected_bytes: u64,
    seconds_to_try: u64,
    buffer: *mut u8,
}

struct TesterFunction {
    name: &'static str,
    mask: u64,
    function: unsafe extern "C" fn(count: u64, data: *mut u8, mask: u64),
    tester: Rc<RefCell<RepetitionTester>>,
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

    let mut functions = vec![
        TesterFunction {
            name: "Mask 16Kb",
            mask: 0b0111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 32Kb",
            mask: 0b1111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 64Kb",
            mask: 0b11111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 128Kb",
            mask: 0b111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 256Kb",
            mask: 0b1111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 512Kb",
            mask: 0b11111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 1Mb",
            mask: 0b111111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 2Mb",
            mask: 0b1111111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
        TesterFunction {
            name: "Mask 4Mb",
            mask: 0b11111111111111111111111,
            function: ReadBufferTest,
            tester: Rc::new(RefCell::new(RepetitionTester::new())),
        },
    ];

    let params = TestParams {
        expected_bytes: total_size as u64,
        seconds_to_try: 2,
        buffer: addr as *mut u8,
    };

    let buffer = unsafe { std::slice::from_raw_parts_mut(addr as *mut u8, total_size) };
    // unsafe {
    //     for i in 0..total_size {
    //         buffer[i] = i as u8;
    //     }
    // }

    loop {
        for ft in &functions {
            println!("\n----- {} -----", ft.name);
            let mut tester = ft.tester.borrow_mut();
            tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
            let total_size = params.expected_bytes as size_t;
            while tester.is_testing() {
                let mut i = 0;
                tester.begin_time();
                unsafe {
                    (ft.function)(total_size as u64, buffer.as_mut_ptr() as *mut u8, ft.mask);
                }
                tester.end_time();
                tester.count_bytes(total_size as u64);
            }
        }
    }
}
