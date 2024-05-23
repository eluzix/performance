extern crate libc;
use libc::{mmap, munmap, PROT_READ, PROT_WRITE, MAP_PRIVATE, MAP_ANON, MAP_FAILED};
use std::ptr;
use crate::perf_metrics::{get_page_faults, VirtualAddress};

pub fn run() {
    let page_size = 4096 * 4;
    let page_count = 2048;
    let total_size = page_size * page_count;
    let pid = std::process::id() as i32;
    println!("Page Count, Touch Count, Fault Count, Extra Faults");

    for touch_count in 1..=page_count {
        let touch_size = page_size * touch_count;

        let addr = unsafe {
            mmap(
                ptr::null_mut(),   // Address at which to start the mapping (nullptr lets the OS choose)
                total_size,       // Number of bytes to map
                PROT_READ | PROT_WRITE, // Enable read and write access
                MAP_PRIVATE | MAP_ANON,
                -1,                // File descriptor not used with MAP_ANON
                0,                 // Offset not used with MAP_ANON
            )
        };

        if addr == MAP_FAILED {
            eprintln!("mmap failed");
            return;
        }

        let start_faults = get_page_faults(pid);
        unsafe {
            let byte_slice = std::slice::from_raw_parts_mut(addr as *mut u8, touch_size);
            for i in 0..touch_size {
                byte_slice[i] = i as u8; // Set each byte to 'i'.
            }
        }
        let end_faults = get_page_faults(pid);
        let fault_count = end_faults - start_faults;

        println!("{}, {}, {}, {}", page_count, touch_count, fault_count, fault_count - touch_count as i32);
        if fault_count > 0 {
            let vaddr = VirtualAddress::from_pointer(addr as usize + touch_size);
            vaddr.print();
        }

        let result = unsafe {
            munmap(addr, total_size)
        };

        if result != 0 {
            eprintln!("munmap failed");
            return;
        }
    }
}
