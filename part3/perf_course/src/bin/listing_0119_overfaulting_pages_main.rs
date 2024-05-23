extern crate libc;

use std::error::Error;
use libc::{mmap, munmap, PROT_READ, PROT_WRITE, MAP_PRIVATE, MAP_ANON, MAP_FAILED};
use std::ptr;

use perf_course::perf_metrics::{get_page_faults, VirtualAddress};

fn main() -> Result<(), Box<dyn Error>> {
    let page_size = 4096*2;
    let page_count = 16384;
    let total_size = page_size * page_count;
    let pid = std::process::id() as i32;

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
        return Ok(());
    }

    let va = VirtualAddress::from_pointer(addr as usize);
    va.print();

    let mut prior_over_fault_count: i32 = 0;
    let mut prior_page_index: usize = 0;

    let start_faults_count = get_page_faults(pid);
    unsafe {
        let byte_slice = std::slice::from_raw_parts_mut(addr as *mut u8, total_size);

        for page_index in 0..page_count {
            let write_index = page_size * page_index;
            // let write_index = total_size - 1 - page_size * page_index;
            byte_slice[write_index] = page_index as u8;
            let end_faults_count = get_page_faults(pid);
            // println!("Writing to page {}", write_index);

            let over_fault_count = end_faults_count - start_faults_count;
            if over_fault_count > prior_over_fault_count {
                println!("Page {}: {} extra faults ({} page size since increase)", page_index, over_fault_count, page_index - prior_page_index);

                if page_index > 0 {
                    let vaddr = VirtualAddress::from_pointer(addr as usize + page_size * prior_page_index);
                    println!("    Previous Pointer: {}", vaddr.format());
                }

                let vaddr = VirtualAddress::from_pointer(addr as usize + page_size * page_index);
                println!("    This Pointer: {}", vaddr.format());

                prior_over_fault_count = over_fault_count;
                prior_page_index = page_index;
            }
        }

        munmap(addr, total_size);
    }

    Ok(())
}
