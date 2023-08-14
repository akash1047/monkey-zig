use std::ffi::{CStr, c_int};
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn read_line(prompt: *const c_char, buffer: *mut c_char, buffer_capacity: c_int) -> c_int {
    let prompt = unsafe { CStr::from_ptr(prompt).to_string_lossy().into_owned() };

    let mut rl = match rustyline::DefaultEditor::new() {
        Ok(r) => r,
        Err(_) => return -6,
    };

    match rl.readline(prompt.as_str()) {
        Ok(line) => {
            if line.len() < buffer_capacity as usize {
                unsafe {
                    std::ptr::copy(line.as_ptr().cast(), buffer, line.len());
                }

                line.len() as i32
            } else {
                -1
            }
        }

        Err(rustyline::error::ReadlineError::Eof) => -2,
        Err(rustyline::error::ReadlineError::Interrupted) => -3,
        Err(rustyline::error::ReadlineError::WindowResized) => -4,
        Err(_) => -5,
    }
}
