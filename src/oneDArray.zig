const std = @import("std");

pub fn main() anyerror!void {
    // Create an allocator (general-purpose allocator for example)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a dynamic array (std.ArrayList)
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit(); // Ensure resources are cleaned up

    // Add elements to the array
    try list.append(10);
    try list.append(20);
    try list.append(30);

    
    // Access and print elements with indices
    for (list.items) |entry| {
        const item = entry;
        std.debug.print("Element : {d}\n", .{item});
    }

    // Modify an element
    list.items[1] = 25;

    // Print modified array
    std.debug.print("Modified array: ", .{});
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}
