const std = @import("std");

pub fn main() !void {


    // Define CSV content
    const csv_content = [_][]const u8{
        "Name,Age,Location",
        "Alice,30,New York",
        "Bob,25,California",
        "Charlie,35,Texas",
    };

    // Open the file for writing
    var file = try std.fs.cwd().createFile("output.csv", .{ .truncate = true });
    defer file.close();

    // Write the CSV content to the file
    for (csv_content) |line| {
        try file.writeAll(line);
        try file.writeAll("\n");
    }

    std.debug.print("CSV file written successfully!\n", .{});
}
