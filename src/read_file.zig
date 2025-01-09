const std = @import("std");

const print = std.debug.print;

fn read_input(allocator: std.mem.Allocator) ![]const u8 {
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

fn readFile(fileName: []const u8) !void {
    const cwd = std.fs.cwd(); // Get current working directory
    const file = try cwd.openFile(fileName, .{});

    defer file.close(); // Ensure file is closed after use

    const file_size = try file.getEndPos(); // Get file size
    const allocator = std.heap.page_allocator;
    const buffer = try allocator.alloc(u8, file_size); // Allocate buffer
    defer allocator.free(buffer); // Free buffer after use

    _ = try file.readAll(buffer); // Read file contents into buffer
    try std.io.getStdOut().writeAll(buffer); // Write buffer content to stdout
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const userInput = try read_input(allocator);
    defer allocator.free(userInput); // Free allocated memory when done

    print("[+] You entered: {s}\n", .{userInput});

   // const fileName = "example.txt";
    try readFile(userInput); // Pass file name to the function
}
