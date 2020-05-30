pub fn kilobytes(bytes: comptime usize) usize {
    return bytes * 1024;
}

pub fn megabytes(bytes: comptime usize) usize {
    return kilobytes(bytes) * 1024;
}

pub fn gigabytes(bytes: comptime usize) usize {
    return megabytes(bytes) * 1024;
}

pub fn terabytes(bytes: comptime usize) usize {
    return gigabytes(bytes) * 1024;
}
