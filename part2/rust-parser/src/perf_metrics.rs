extern crate libc;
extern crate mach;

use std::mem;
use std::time::Duration;

use libc::{c_int, c_void, pid_t};
use mach::mach_time::{mach_absolute_time, mach_timebase_info};

#[repr(C)]
#[repr(C)]
struct ProcTaskInfo {
    pti_virtual_size: u64,      // virtual memory size (bytes)
    pti_resident_size: u64,     // resident memory size (bytes)
    pti_total_user: u64,        // total user CPU time
    pti_total_system: u64,      // total system CPU time
    pti_threads_user: u64,      // user CPU time of threads
    pti_threads_system: u64,    // system CPU time of threads
    pti_policy: i32,            // default policy for new threads
    pti_faults: i32,            // number of page faults
    pti_pageins: i32,           // number of pageins
    pti_cow_faults: i32,        // number of copy-on-write faults
    pti_messages_sent: i32,     // number of messages sent
    pti_messages_received: i32, // number of messages received
    pti_syscalls_mach: i32,     // number of mach system calls
    pti_syscalls_unix: i32,     // number of unix system calls
    pti_csw: i32,               // number of context switches
    pti_threadnum: i32,         // number of threads in the task
    pti_numrunning: i32,        // number of running threads
    pti_priority: i32,          // task priority
}

extern "C" {
    fn proc_pidinfo(
        pid: pid_t,
        flavor: c_int,
        arg: u64,
        info: *mut c_void,
        info_size: c_int,
    ) -> c_int;
}

pub fn get_page_faults(pid: pid_t) -> i32 {
    let mut task_info = ProcTaskInfo {
        pti_virtual_size: 0,
        pti_resident_size: 0,
        pti_total_user: 0,
        pti_total_system: 0,
        pti_threads_user: 0,
        pti_threads_system: 0,
        pti_policy: 0,
        pti_faults: 0,
        pti_pageins: 0,
        pti_cow_faults: 0,
        pti_messages_sent: 0,
        pti_messages_received: 0,
        pti_syscalls_mach: 0,
        pti_syscalls_unix: 0,
        pti_csw: 0,
        pti_threadnum: 0,
        pti_numrunning: 0,
        pti_priority: 0,
    };

    let size = mem::size_of::<ProcTaskInfo>() as c_int;
    let result = unsafe {
        proc_pidinfo(
            pid,
            4, // PROC_PIDTASKINFO constant
            0,
            &mut task_info as *mut _ as *mut c_void,
            size,
        )
    };
    // if result == 0 {
    //     return 0;
    // }

    if result == size {
        task_info.pti_faults
    } else {
        eprintln!("Failed to get process info");
        -1
    }
}

pub fn high_resolution_info() -> mach_timebase_info {
    unsafe {
        let mut info = mach_timebase_info { numer: 0, denom: 0 };
        mach_timebase_info(&mut info);
        info
    }
}

pub fn high_resolution_time() -> u64 {
    unsafe { mach_absolute_time() }
}

pub fn high_resolution_clock() -> Duration {
    unsafe {
        let time = mach_absolute_time();
        let mut info = mach_timebase_info { numer: 0, denom: 0 };
        mach_timebase_info(&mut info);
        let nanos = time * info.numer as u64 / info.denom as u64;
        Duration::from_nanos(nanos)
    }
}


#[derive(Debug)]
pub struct VirtualAddress {
    l1_index: u16,
    l2_index: u16,
    l3_index: u16,
    l4_index: u16,
    offset: u16,
}

impl VirtualAddress {
    pub fn from_pointer(pointer: usize) -> Self {
        VirtualAddress {
            l1_index: ((pointer >> 47) & 0x1) as u16,
            l2_index: ((pointer >> 36) & 0x7FF) as u16,
            l3_index: ((pointer >> 25) & 0x7FF) as u16,
            l4_index: ((pointer >> 14) & 0x7FF) as u16,
            offset: (pointer & 0x03FFF) as u16,
        }
    }

    pub fn print(&self) {
        println!("{} | {} | {} | {} | {}",
                 self.l1_index,
                 self.l2_index,
                 self.l3_index,
                 self.l4_index,
                 self.offset
        );
    }
}
