use std::{ffi, ptr};

#[no_mangle]
pub extern "C" fn artichoke_download_and_parse(
    s: *const libc::c_char,
) -> Option<ptr::NonNull<libc::c_char>> {
    let path = unsafe {
        assert!(!s.is_null());
        ffi::CStr::from_ptr(s)
    };

    let content = artichoke::fetch_info(&path.to_string_lossy());
    artichoke::parse(&content)
        .map(artichoke::frontmatter)
        .map(String::into_bytes)
        .map(|x| unsafe { ffi::CString::from_vec_unchecked(x) })
        .map(ffi::CString::into_raw)
        .and_then(ptr::NonNull::new)
}

#[no_mangle]
pub extern "C" fn artichoke_parse(s: *const libc::c_char) -> Option<ptr::NonNull<libc::c_char>> {
    let content = unsafe {
        assert!(!s.is_null());
        ffi::CStr::from_ptr(s)
    };
    artichoke::parse(&content.to_string_lossy())
        .map(artichoke::frontmatter)
        .map(String::into_bytes)
        .map(|x| unsafe { ffi::CString::from_vec_unchecked(x) })
        .map(ffi::CString::into_raw)
        .and_then(ptr::NonNull::new)
}
