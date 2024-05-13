use std::cell::RefCell;
use std::fs::File;
use std::io::Read;
use std::rc::Rc;

use crate::repetition_tester::repetition_tester::RepetitionTester;

struct TestParams {
    file_name: &'static str,
    expected_bytes: u64,
    seconds_to_try: u64,
}

fn run_full_read_test(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    let mut buffer = Vec::with_capacity(params.expected_bytes as usize);

    while tester.is_testing() {
        let mut verify_file = File::open(params.file_name).unwrap();
        buffer.clear();

        tester.begin_time();
        match verify_file.read_to_end(&mut buffer) {
            Ok(_) => {}
            Err(e) => {
                tester.set_error(&format!("Error reading file: {:?}", e));
            }
        }
        tester.end_time();

        tester.count_bytes(buffer.len() as u64);
    }
}

fn run_buffered_read_test(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);
    const BUFFER_SIZE: usize = 8096 * 100;
    let mut buffer = [0_u8; BUFFER_SIZE];

    while tester.is_testing() {
        let mut reader = File::open(params.file_name).unwrap();
        let mut total_bytes_read = 0;

        tester.begin_time();
        let mut count = reader.read(&mut buffer).unwrap();
        total_bytes_read += count;
        while count > 0 {
            count = reader.read(&mut buffer).unwrap();
            total_bytes_read += count;
        }
        tester.end_time();
        tester.count_bytes(total_bytes_read as u64);
    }
}

fn run_read_file_to_string_test(tester: &mut RepetitionTester, params: &TestParams) {
    tester.start_test_wave(params.seconds_to_try, params.expected_bytes);

    while tester.is_testing() {
        tester.begin_time();
        let str = std::fs::read_to_string(params.file_name).unwrap();
        tester.end_time();
        tester.count_bytes(str.len() as u64);
    }
}

fn get_test_params() -> TestParams {
    let file_name = "haversine_data.json";
    let file = File::open(file_name).unwrap();
    let expected_bytes = file.metadata().unwrap().len();
    TestParams {
        file_name,
        expected_bytes,
        seconds_to_try: 3,
    }
}

pub fn run() {
    let params = get_test_params();

    let testers = vec![
        Rc::new(RefCell::new(RepetitionTester::new())),
        Rc::new(RefCell::new(RepetitionTester::new())),
        Rc::new(RefCell::new(RepetitionTester::new())),
    ];

    let mut test_functions: Vec<(&str, Box<dyn FnMut()>)> = vec![
        (
            "Buffered Read Test",
            Box::new({
                let tester = Rc::clone(&testers[1]);
                let params = &params;
                move || {
                    run_buffered_read_test(&mut *tester.borrow_mut(), params);
                }
            }),
        ),
        (
            "Full Read Test",
            Box::new({
                let tester = Rc::clone(&testers[0]);
                let params = &params;
                move || {
                    run_full_read_test(&mut *tester.borrow_mut(), params);
                }
            }),
        ),
        (
            "Read To String Test",
            Box::new({
                let tester = Rc::clone(&testers[2]);
                let params = &params;
                move || {
                    run_read_file_to_string_test(&mut *tester.borrow_mut(), params);
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
