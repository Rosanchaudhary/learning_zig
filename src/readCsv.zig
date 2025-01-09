const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Open the CSV file
    const cwd = std.fs.cwd();
    const file = try cwd.openFile("Book1.csv", .{});
    defer file.close();

    // Read the file contents into a buffer
    const file_size = try file.getEndPos();
    var buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    // Check for BOM and skip if present
    var content: []const u8 = buffer[0..];
    if (content.len >= 3 and std.mem.eql(u8, content[0..3], "\xEF\xBB\xBF")) {
        content = content[3..]; // Skip the BOM
    }

    // Create a 2D dynamic array (ArrayList of ArrayLists)
    var matrix = std.ArrayList(std.ArrayList([]const u8)).init(allocator);
    defer {
        for (matrix.items) |row| {
            row.deinit();
        }
        matrix.deinit();
    }

    // Split rows by newline
    var rows = std.mem.splitSequence(u8, content, "\n");

    // Iterate through each row
    while (rows.next()) |row| {
        var row_data = std.ArrayList([]const u8).init(allocator);

        // Split the row by commas to get columns
        var cols = std.mem.splitSequence(u8, row, ",");
        while (cols.next()) |col| {
            try row_data.append(col);
        }

        // Add the completed row to the matrix
        try matrix.append(row_data);
    }

    // Debug print the content of the matrix
    // for (matrix.items) |row| {
    //     for (row.items) |col| {
    //         std.debug.print("{s} ", .{col});
    //     }
    //     std.debug.print("\n", .{});
    // }

    // Example: Print the first element from the first row
    if (matrix.items.len > 0 and matrix.items[0].items.len > 0) {
        std.debug.print("{s}\n", .{matrix.items[1].items[0]});
    } else {
        std.debug.print("No elements to print.\n", .{});
    }
}
