use std::time::Duration;
use once_cell::unsync::Lazy;
extern crate mach;

use mach::mach_time::{mach_absolute_time, mach_timebase_info};

fn high_resolution_clock() -> Duration {
    unsafe {
        let time = mach_absolute_time();
        let mut info = mach_timebase_info { numer: 0, denom: 0 };
        mach_timebase_info(&mut info);
        let nanos = time * info.numer as u64 / info.denom as u64;
        Duration::from_nanos(nanos)
    }
}

#[derive(Debug, Clone)]
pub struct TimePoint {
    start_time: Duration,
    total_time: Duration,
    label: String,
    hit_count: u32,
    children_time: Duration,
    parent_index: Option<usize>,
}

impl TimePoint {
    fn new(label: &str) -> Self {
        TimePoint {
            start_time: high_resolution_clock(),
            total_time: Duration::new(0, 0),
            label: label.to_string(),
            hit_count: 0,
            children_time: Duration::new(0, 0),
            parent_index: None,
        }
    }

    fn mark_span(&mut self) -> Duration {
        let time = high_resolution_clock() - self.start_time;
        self.start_time = high_resolution_clock();
        self.total_time += time;
        self.hit_count += 1;
        time
    }
}

pub struct NaiveProfiler {
    time_points: Vec<TimePoint>,
    start_time: Option<Duration>,
    elapsed_time: Option<Duration>,
    // root_index: Option<usize>,
    stack: Vec<usize>,
}

impl NaiveProfiler {
    fn new() -> Self {
        NaiveProfiler {
            time_points: Vec::with_capacity(4096),
            start_time: None,
            elapsed_time: None,
            stack: Vec::with_capacity(64),
        }
    }

    fn start_profiling(&mut self) {
        self.start_time = Some(high_resolution_clock());
    }

    fn stop_profiling(&mut self) {
        if let Some(start) = self.start_time.take() {
            self.elapsed_time = Some(high_resolution_clock() - start);
        }
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

            let index = profiler.time_points.len() - 1;

            if !profiler.stack.is_empty() {
                let parent_index = *profiler.stack.last().unwrap();
                profiler.time_points[index].parent_index = Some(parent_index);
            }

            index
        }
    };

    if profiler.stack.is_empty() {
        profiler.stack.push(index);
    } else {
        let latest_root_index = *profiler.stack.last().unwrap();
        if latest_root_index != index {
            profiler.stack.push(index);
        }
    }

    index
}

#[cfg(feature = "profiler")]
pub fn stop_span(index: usize) {
    let profiler = unsafe { &mut NAIVE_PROFILER };
    if let Some(time_point) = profiler.time_points.get_mut(index) {
        let elapsed = time_point.mark_span();

        if let Some(parent_index) = time_point.parent_index {
            let parent_time_point = &mut profiler.time_points[parent_index];
            parent_time_point.children_time += elapsed;

            let latest_root_index = *profiler.stack.last().unwrap();
            if latest_root_index == index {
                profiler.stack.pop();
            }
        }

        if !profiler.stack.is_empty() {
            let latest_root_index = *profiler.stack.last().unwrap();
            if latest_root_index == index {
                profiler.stack.pop();
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
    let total_time = profiler.elapsed_time.unwrap();
    for point in &profiler.time_points {
        // println!("{}: {:?} {:?}", point.label, point.total_time, point.children_time);
        // let point_total_time = point.total_time;
        let point_total_time = point.total_time - point.children_time;
        let percent = (point_total_time.as_secs_f64() / total_time.as_secs_f64()) * 100.0;
        println!("{}: {:?} ({} hits, {:.2}%)", point.label, point_total_time, point.hit_count, percent);
    }
    println!("Total time: {:?}", total_time);
}
