pub fn kilobytes(bytes: comptime_int) comptime_int {
    return bytes * 1024;
}

pub fn megabytes(bytes: comptime_int) comptime_int {
    return kilobytes(bytes) * 1024;
}

pub fn gigabytes(bytes: comptime_int) comptime_int {
    return megabytes(bytes) * 1024;
}

pub fn terabytes(bytes: comptime_int) comptime_int {
    return gigabytes(bytes) * 1024;
}
