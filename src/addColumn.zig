const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create a dynamic 2D array (list of rows)
    var rows = std.ArrayList(std.ArrayList([]const u8)).init(allocator);

    // Initialize and append rows
    var header = std.ArrayList([]const u8).init(allocator);
    try header.append("Name");
    try header.append("Age");
    try header.append("Country");
    try rows.append(header);

    var row1 = std.ArrayList([]const u8).init(allocator);
    try row1.append("Alice");
    try row1.append("25");
    try row1.append("USA");
    try rows.append(row1);

    var row2 = std.ArrayList([]const u8).init(allocator);
    try row2.append("Bob");
    try row2.append("30");
    try row2.append("UK");
    try rows.append(row2);

    var row3 = std.ArrayList([]const u8).init(allocator);
    try row3.append("Charlie");
    try row3.append("22");
    try row3.append("Nepal");
    try rows.append(row3);

    // Display the initial table
    std.debug.print("Initial Table Data:\n", .{});
    for (rows.items) |row| {
        for (row.items) |col| {
            std.debug.print("{s:12}", .{col});
        }
        std.debug.print("\n", .{});
    }

    // Add a new column: "Occupation"
    try rows.items[0].append("Occupation"); // Update the header row
    try rows.items[1].append("Engineer");
    try rows.items[2].append("Doctor");
    try rows.items[3].append("Student");

    // Display the updated table
    std.debug.print("\nUpdated Table Data:\n", .{});
    for (rows.items) |row| {
        for (row.items) |col| {
            std.debug.print("{s:12}", .{col});
        }
        std.debug.print("\n", .{});
    }

    // Free memory used by each row and the main ArrayList
    for (rows.items) |row| {
        row.deinit();
    }
    rows.deinit();
}
