const std = @import("std");

const print = std.debug.print;

pub fn read_input(allocator: std.mem.Allocator) ![]const u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("[+] Enter your input: ", .{});

    var buffer: [128]u8 = undefined; // Temporary stack buffer
    const result = try stdin.readUntilDelimiterOrEof(buffer[0..], '\n');

    if (result) |bytes_read| {
        if (bytes_read.len == 0) {
            return error.InvalidInput;
        }

        // Remove trailing newline, if present
        const trimmed = std.mem.trimRight(u8, bytes_read, "\n");

        // Allocate and copy the result into a dynamic buffer
        return try allocator.dupe(u8, trimmed);
    } else {
        return error.InputError; // Handle case where result is null
    }
}