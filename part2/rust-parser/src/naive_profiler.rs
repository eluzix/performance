use std::sync::Mutex;
use std::time::Duration;
use cpu_time::ProcessTime;
use once_cell::unsync::Lazy;

#[derive(Debug, Clone)]
pub struct TimePoint {
    start_time: ProcessTime,
    total_time: Duration,
    label: String,
    hit_count: u32,
    children_time: Duration,
}

impl TimePoint {
    fn new(label: &str) -> Self {
        TimePoint {
            start_time: ProcessTime::now(),
            total_time: Duration::new(0, 0),
            label: label.to_string(),
            hit_count: 0,
            children_time: Duration::new(0, 0),
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
    root_index: Option<usize>,
}

impl NaiveProfiler {
    fn new() -> Self {
        NaiveProfiler {
            time_points: Vec::with_capacity(4096),
            start_time: None,
            elapsed_time: None,
            root_index: None,
        }
    }

    fn start_profiling(&mut self) {
        self.start_time = Some(ProcessTime::now());
    }

    fn stop_profiling(&mut self) {
        if let Some(start) = self.start_time.take() {
            self.elapsed_time = Some(start.elapsed());
        }
        // self.elapsed_time = Some(self.start_time.unwrap().elapsed());
    }

    fn report(&self) {
        let total_time = self.elapsed_time.unwrap();
        for point in &self.time_points {
            // println!("{}: {:?} {:?}", point.label, point.total_time, point.children_time);
            // let point_total_time = point.total_time;
            let point_total_time = point.total_time - point.children_time;
            let percent = (point_total_time.as_secs_f64() / total_time.as_secs_f64()) * 100.0;
            // print the children time
            // println!("{}: {:?}", point.label, point.children_time);
            println!("{}: {:?} ({} hits, {:.2}%)", point.label, point_total_time, point.hit_count, percent);
        }
        println!("Total time: {:?}", total_time);
    }
}

pub static mut NAIVE_PROFILER: Lazy<NaiveProfiler> = Lazy::new(|| NaiveProfiler::new());

pub fn start_profiling() {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    profiler.start_profiling();
}

pub fn stop_profiling() {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    profiler.stop_profiling();
}

#[cfg(feature = "profiler")]
pub fn start_span(label: &str) -> usize {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    let idx = profiler.time_points.iter().position(|p| p.label == label);

    let index = match idx {
        Some(index) => index,
        None => {
            let tp = TimePoint::new(label);
            profiler.time_points.push(tp);
            profiler.time_points.len() - 1
        }
    };

    if profiler.root_index.is_none() {
        profiler.root_index = Some(index);
    }

    index
}

#[cfg(feature = "profiler")]
pub fn stop_span(index: usize) {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    if let Some(time_point) = profiler.time_points.get_mut(index) {
        let elapsed = time_point.start_time.elapsed() - time_point.total_time;
        time_point.add_time(elapsed);

        if let Some(root_index) = profiler.root_index {
            if root_index != index {
                let root_time_point = &mut profiler.time_points[root_index];
                root_time_point.children_time += elapsed;
            } else {
                profiler.root_index = None; // Clear root when root span stops
            }
        }
    }
}

#[cfg(not(feature = "profiler"))]
pub fn start_span(_: &str) -> usize {
    0 // Dummy index
}

#[cfg(not(feature = "profiler"))]
pub fn stop_span(_: usize) {}

pub fn report() {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    profiler.report();
}
