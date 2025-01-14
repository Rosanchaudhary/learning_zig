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
    printTable(rows);

    // Add a new column: "Occupation"
    try rows.items[0].append("Occupation"); // Update the header row
    try rows.items[1].append("Engineer");
    try rows.items[2].append("Doctor");
    try rows.items[3].append("Student");

    // Display the updated table with the new column
    std.debug.print("\nTable with New Column:\n", .{});
    printTable(rows);

    // Remove a column by name
    try removeColumnByName(&rows, "Age");

    // Display the updated table after column removal
    std.debug.print("\nTable After Removing 'Age' Column:\n", .{});
    printTable(rows);

    // Free memory used by each row and the main ArrayList
    for (rows.items) |row| {
        row.deinit();
    }
    rows.deinit();
}

// Function to print the table
fn printTable(rows: std.ArrayList(std.ArrayList([]const u8))) void {
    for (rows.items) |row| {
        for (row.items) |col| {
            std.debug.print("{s:12}", .{col});
        }
        std.debug.print("\n", .{});
    }
}

// Function to remove a column by name
fn removeColumnByName(rows: *std.ArrayList(std.ArrayList([]const u8)), colName: []const u8) !void {
    if (rows.items.len == 0) return; // If the table is empty, do nothing

    // Find the index of the column in the header row
    const header = &rows.items[0];
    var colIndex: ?usize = null;
    var index: usize = 0;
    for (header.items) |col| {
        if (std.mem.eql(u8, col, colName)) {
            colIndex = index;
            break;
        }
        index += 1;
    }

    // If the column is not found, return an error
    if (colIndex == null) return error.InvalidColumnName;

    // Remove the column from each row by shifting elements

    for (rows.items) |row| {
        var rowItemsLen: usize = row.items.len;
        var targetIndex = colIndex.?;
        while (targetIndex < rowItemsLen - 1) {
            row.items[targetIndex] = row.items[targetIndex + 1];
            targetIndex += 1;
        }
        rowItemsLen -= 1; // Decrement the length to remove the last element
    }
}