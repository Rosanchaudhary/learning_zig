const std = @import("std");

pub fn main() anyerror!void {
    // Create an allocator (general-purpose allocator for example)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a dynamic 2D array (ArrayList of ArrayLists)
    var matrix = std.ArrayList(std.ArrayList(i32)).init(allocator);
    defer {
        // Ensure rows are properly deinitialized
        for (matrix.items) |row| {
            row.deinit();
        }
        matrix.deinit();
    }

    const initialValues: [3][3]i32 = [_][3]i32{
        [_]i32{ 1, 2, 3 },
        [_]i32{ 4, 5, 6 },
        [_]i32{ 7, 8, 9 },
    };

    // Iterate over each row in the initial values
    for (initialValues) |rowValues| {
        // Create a new row as a dynamic array
        var row = std.ArrayList(i32).init(allocator);

        // Append each value to the row
        for (rowValues) |value| {
            try row.append(value);
        }

        // Add the completed row to the matrix
        try matrix.append(row);
    }

    std.debug.print("This is matrix {}", .{matrix.items[2].items[2]});

    // // Print the matrix
    // const stdout = std.io.getStdOut().writer();
    // try stdout.print("Matrix:\n", .{});
    // for (matrix.items) |row| {
    //     try stdout.print("[", .{});
    //     for (row.items) |value| {
    //         try stdout.print("{d}", .{value});
    //     }
    //     try stdout.print("]\n", .{});
    // }
}
