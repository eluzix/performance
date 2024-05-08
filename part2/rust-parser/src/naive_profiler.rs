use std::time::Duration;
use cpu_time::ProcessTime;
use once_cell::unsync::Lazy;

#[derive(Debug, Clone)]
pub struct TimePoint {
    start_time: ProcessTime,
    total_time: Duration,
    label: String,
    hit_count: u32,
}

impl TimePoint {
    fn new(label: &str) -> Self {
        TimePoint {
            start_time: ProcessTime::now(),
            total_time: Duration::new(0, 0),
            label: label.to_string(),
            hit_count: 0,
        }
    }

    fn add_time(&mut self, time: Duration) {
        self.total_time += time;
        self.hit_count += 1;
    }
}

pub struct NaiveProfiler {
    time_points: Vec<TimePoint>,
    start_time: Option<ProcessTime>,
    elapsed_time: Option<Duration>,
}

impl NaiveProfiler {
    fn new() -> Self {
        NaiveProfiler {
            time_points: Vec::with_capacity(4096),
            start_time: None,
            elapsed_time: None,
        }
    }

    fn start_profiling(&mut self) {
        self.start_time = Some(ProcessTime::now());
    }

    fn stop_profiling(&mut self) {
        self.elapsed_time = Some(self.start_time.unwrap().elapsed());
    }

    fn report(&self) {
        let total_time = self.elapsed_time.unwrap();
        for point in &self.time_points {
            println!("{}: {:?} ({} hits)", point.label, point.total_time, point.hit_count);
        }
        println!("Total time: {:?}", total_time);
    }
}

pub static mut NAIVE_PROFILER: Lazy<NaiveProfiler> = Lazy::new(|| NaiveProfiler::new());

pub fn measure_anchor(mut time_point: TimePoint) {
    let elapsed = time_point.start_time.elapsed();

    let profiler = unsafe { &mut NAIVE_PROFILER };

    let mut found = false;
    for point in &mut profiler.time_points {
        if point.label == time_point.label {
            point.add_time(elapsed);
            found = true;
            break;
        }
    }

    if !found {
        time_point.add_time(elapsed);
        profiler.time_points.push(time_point.clone());
    }
}

pub fn start_profiling() {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    profiler.start_profiling();
}

pub fn stop_profiling() {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    profiler.stop_profiling();
}

#[cfg(feature = "profiler")]
pub fn start_span(label: &str) -> TimePoint {
    TimePoint::new(label)
}

#[cfg(feature = "profiler")]
pub fn stop_span(time_point: &TimePoint) {
    measure_anchor(time_point.clone());
}

#[cfg(not(feature = "profiler"))]
pub fn start_span(_: &str) -> &'static TimePoint {
    static mut TIME_POINT: Option<TimePoint> = None;
    unsafe {
        TIME_POINT.get_or_insert_with(|| {
            TimePoint::new("dummy")
        })
    }
}

#[cfg(not(feature = "profiler"))]
pub fn stop_span(_time_point: &TimePoint) {}

pub fn report() {
    let profiler = unsafe { &NAIVE_PROFILER };
    profiler.report();
}
