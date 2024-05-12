pub mod repetition_tester {
    use crate::perf_metrics::{get_page_faults, high_resolution_info, high_resolution_time};
    use mach::mach_time::mach_timebase_info;
    use std::io::Write;
    use std::time::Duration;

    #[derive(PartialEq, Copy, Debug, Clone)]
    enum State {
        Uninitialized,
        Testing,
        Completed,
        Error,
    }

    #[derive(Debug, Copy, Clone)]
    enum RepetitionTesterMetrics {
        TestCount,
        Time,
        PageFaults,
        ByteCount,

        Count,
    }

    #[derive(Debug, Copy, Clone)]
    pub struct RepetitionTesterResults {
        pub totals: [u64; RepetitionTesterMetrics::Count as usize],
        pub min: [u64; RepetitionTesterMetrics::Count as usize],
        pub max: [u64; RepetitionTesterMetrics::Count as usize],
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
        test_metrics: [u64; RepetitionTesterMetrics::Count as usize],

        results: RepetitionTesterResults,

        pid: i32,
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
                pid: std::process::id() as i32,

                test_metrics: [0; RepetitionTesterMetrics::Count as usize],
                results: RepetitionTesterResults {
                    totals: [0; RepetitionTesterMetrics::Count as usize],
                    min: [0; RepetitionTesterMetrics::Count as usize],
                    max: [0; RepetitionTesterMetrics::Count as usize],
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
                    self.expected_bytes = expected_bytes;
                    self.results = RepetitionTesterResults {
                        totals: [0; RepetitionTesterMetrics::Count as usize],
                        min: [0; RepetitionTesterMetrics::Count as usize],
                        max: [0; RepetitionTesterMetrics::Count as usize],
                    };
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
            self.test_metrics[RepetitionTesterMetrics::Time as usize] = high_resolution_time();
            self.test_metrics[RepetitionTesterMetrics::PageFaults as usize] =
                get_page_faults(self.pid) as u64;
        }

        pub fn end_time(&mut self) {
            self.close_blocks_count += 1;
            self.test_metrics[RepetitionTesterMetrics::Time as usize] =
                high_resolution_time() - self.test_metrics[RepetitionTesterMetrics::Time as usize];
            self.test_metrics[RepetitionTesterMetrics::PageFaults as usize] =
                get_page_faults(self.pid) as u64
                    - self.test_metrics[RepetitionTesterMetrics::PageFaults as usize];
        }

        pub fn count_bytes(&mut self, bytes: u64) {
            self.test_metrics[RepetitionTesterMetrics::ByteCount as usize] += bytes;
        }

        pub fn is_testing(&mut self) -> bool {
            if self.state == State::Testing {
                let current_time = high_resolution_time();
                if self.open_blocks_count > 0 {
                    if self.open_blocks_count != self.close_blocks_count {
                        self.set_error("Open and close blocks do not match");
                    }

                    if self.test_metrics[RepetitionTesterMetrics::ByteCount as usize]
                        != self.expected_bytes
                    {
                        self.set_error("Byte count does not match expected bytes");
                    }

                    if self.state == State::Testing {
                        self.test_metrics[RepetitionTesterMetrics::TestCount as usize] = 1;

                        for i in 0..RepetitionTesterMetrics::Count as usize {
                            self.results.totals[i] += self.test_metrics[i];
                        }

                        if self.results.max[RepetitionTesterMetrics::Time as usize]
                            < self.test_metrics[RepetitionTesterMetrics::Time as usize]
                        {
                            self.results.max = self.test_metrics;
                        }

                        if self.results.min[RepetitionTesterMetrics::Time as usize] == 0
                            || self.results.min[RepetitionTesterMetrics::Time as usize]
                                > self.test_metrics[RepetitionTesterMetrics::Time as usize]
                        {
                            self.results.min = self.test_metrics;

                            self.start_time = current_time;
                            self.print_time("Min", self.results.min, true);
                        }

                        self.open_blocks_count = 0;
                        self.close_blocks_count = 0;
                        self.test_metrics = [0; RepetitionTesterMetrics::Count as usize];
                    }

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
            seconds * 1_000_000_00 * self.cpu_timebase_info.denom as u64
                / self.cpu_timebase_info.denom as u64
        }

        fn time_as_seconds(&mut self, time: u64) -> Duration {
            Duration::from_nanos(
                time * self.cpu_timebase_info.numer as u64 / self.cpu_timebase_info.denom as u64,
            )
        }

        // fn print_time(&mut self, label: &str, time: u64, bytes: u64, carrier_return: bool) {
        fn print_time(
            &mut self,
            label: &str,
            value: [u64; RepetitionTesterMetrics::Count as usize],
            carrier_return: bool,
        ) {
            let test_count = value[RepetitionTesterMetrics::TestCount as usize];
            let mut local_value = [0; RepetitionTesterMetrics::Count as usize];
            for i in 0..RepetitionTesterMetrics::Count as usize {
                local_value[i] = value[i] / test_count as u64;
            }

            let time = local_value[RepetitionTesterMetrics::Time as usize];
            let time_in_seconds = self.time_as_seconds(time);
            // println!("{}: {} ({}s)", label, time, time_in_seconds.as_secs_f64());

            print!("{}: {} ({}s)", label, time, time_in_seconds.as_secs_f64());

            let bytes = local_value[RepetitionTesterMetrics::ByteCount as usize];
            if bytes > 0 {
                let gb_processed = bytes as f64 / (1024.0 * 1024.0 * 1024.0);
                let bandwidth = gb_processed / time_in_seconds.as_secs_f64();
                print!(" ({:.10} GB/s)", bandwidth);
            }

            let page_faults = local_value[RepetitionTesterMetrics::PageFaults as usize];
            if page_faults > 0 {
                print!(
                    " (PF: {:.4}, {:.4}k/fault)",
                    page_faults,
                    bytes as f64 / (page_faults as f64 * 1024.0)
                );
            }

            if carrier_return {
                print!("                   \r");
                std::io::stdout().flush().unwrap();
            } else {
                println!();
            }
        }

        fn print_results(&mut self) {
            self.print_time("Min", self.results.min, false);
            self.print_time("Max", self.results.max, false);
            self.print_time("Avg.", self.results.totals, false);
        }
    }
}
