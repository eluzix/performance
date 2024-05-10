use std::io;

pub mod repetition_tester {
    use std::io::Write;
    use std::time::Duration;
    use mach::mach_time::mach_timebase_info;
    use crate::naive_profiler::{high_resolution_info, high_resolution_time};

    #[derive(PartialEq, Copy, Debug, Clone)]
    enum State {
        Uninitialized,
        Testing,
        Completed,
        Error,
    }

    #[derive(Debug, Copy, Clone)]
    pub struct RepetitionTesterResults {
        pub test_count: u64,
        pub total_time: u64,
        pub max_time: u64,
        pub min_time: u64,
    }

    #[derive(Debug, Copy, Clone)]
    pub struct RepetitionTester {
        state: State,
        start_time: u64,
        time_to_wait: u64,
        cpu_timebase_info: mach_timebase_info,

        open_blocks_count: u32,
        close_blocks_count: u32,

        expected_bytes: u64,
        total_bytes_accumulated: u64,
        total_time_accumulated: u64,

        results: RepetitionTesterResults,
    }

    impl RepetitionTester {
        pub fn new() -> Self {
            RepetitionTester {
                state: State::Uninitialized,
                start_time: 0,
                time_to_wait: 0,
                cpu_timebase_info: high_resolution_info(),
                open_blocks_count: 0,
                close_blocks_count: 0,
                expected_bytes: 0,
                total_bytes_accumulated: 0,
                total_time_accumulated: 0,

                results: RepetitionTesterResults {
                    test_count: 0,
                    total_time: 0,
                    max_time: 0,
                    min_time: 0,
                },
            }
        }

        pub fn start_test_wave(&mut self, seconds_to_try: u64, expected_bytes: u64) {
            match self.state {
                State::Uninitialized => {
                    self.state = State::Testing;
                    self.start_time = high_resolution_time();
                    self.open_blocks_count = 0;
                    self.close_blocks_count = 0;
                    self.total_bytes_accumulated = 0;
                    self.total_time_accumulated = 0;
                    self.expected_bytes = expected_bytes;

                }
                State::Completed => {
                    self.state = State::Testing;
                }
                State::Testing => {
                    self.set_error("Test wave already in progress");
                }
                State::Error => {
                    self.set_error("Cannot start test wave from error state");
                }
            }

            self.start_time = high_resolution_time();
            self.time_to_wait = self.time_from_seconds(seconds_to_try);
        }

        pub fn set_error(&mut self, error: &str) {
            self.state = State::Error;
            eprintln!("[RepetitionTester] Error: {}", error);
        }

        pub fn begin_time(&mut self) {
            self.open_blocks_count += 1;
            // self.start_time = high_resolution_time();
            self.total_time_accumulated = high_resolution_time();
        }

        pub fn end_time(&mut self) {
            self.close_blocks_count += 1;
            self.total_time_accumulated = high_resolution_time() - self.total_time_accumulated;
        }

        pub fn count_bytes(&mut self, bytes: u64) {
            self.total_bytes_accumulated += bytes;
        }

        pub fn is_testing(&mut self) -> bool {
            if self.state == State::Testing {
                let current_time = high_resolution_time();
                if self.open_blocks_count > 0 {
                    if self.open_blocks_count != self.close_blocks_count {
                        self.set_error("Open and close blocks do not match");
                    }

                    if self.state == State::Testing {
                        let elapsed_time = self.total_time_accumulated;
                        self.results.test_count += 1;
                        self.results.total_time += elapsed_time;

                        if self.results.max_time < elapsed_time {
                            self.results.max_time = elapsed_time;
                        }

                        if self.results.min_time == 0 || self.results.min_time > elapsed_time {
                            self.results.min_time = elapsed_time;

                            self.start_time = current_time;
                            self.print_time("Min", self.results.min_time, self.total_bytes_accumulated, true);
                        }

                        self.open_blocks_count = 0;
                        self.close_blocks_count = 0;
                        self.total_bytes_accumulated = 0;
                        self.total_time_accumulated = 0;
                    }
                    // print current time, start time, and time to wait
                    // println!("- time: {}, Current time: {}, Start time: {}, Time to wait: {}", current_time - self.start_time, current_time, self.start_time, self.time_to_wait);
                    if current_time - self.start_time > self.time_to_wait {
                        self.state = State::Completed;
                        self.print_results();
                    }
                }
            }

            self.state == State::Testing
        }


        // helper functions
        fn time_from_seconds(&mut self, seconds: u64) -> u64 {
            seconds * 1_000_000_00 * self.cpu_timebase_info.denom as u64 / self.cpu_timebase_info.denom as u64
        }

        fn time_as_seconds(&mut self, time: u64) -> Duration {
            Duration::from_nanos(time * self.cpu_timebase_info.numer as u64 / self.cpu_timebase_info.denom as u64)
        }

        fn print_time(&mut self, label: &str, time: u64, bytes: u64, carrier_return: bool) {
            let time_in_seconds = self.time_as_seconds(time);
            // println!("{}: {} ({}s)", label, time, time_in_seconds.as_secs_f64());

            print!("{}: {} ({}s)", label, time, time_in_seconds.as_secs_f64());

            if bytes > 0 {
                let gb_processed = bytes as f64 / (1024.0 * 1024.0 * 1024.0);
                let bandwidth = gb_processed / time_in_seconds.as_secs_f64();
                print!(" ({:.10} GB/s)", bandwidth);
            }

            if carrier_return {
                print!("                   \r");
                std::io::stdout().flush().unwrap();
            } else {
                println!();
            }
        }

        fn print_results(&mut self) {
            self.print_time("Min", self.results.min_time, self.expected_bytes, false);
            self.print_time("Max", self.results.max_time, self.expected_bytes, false);

            if self.results.test_count > 1 {
                let average_time = self.results.total_time / self.results.test_count;
                self.print_time("Average", average_time, self.expected_bytes, false);
            }
        }
    }
}
