const std = @import("std");
pub const CsvParser = @import("CsvParser.zig").CsvParser;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var csv_parser = CsvParser.init(&allocator);
    defer csv_parser.deinit();

    try csv_parser.readCsv("mnist_test.csv", true);

    // try csv_parser.addColumn("Hobby", &[_][]const u8{ "Games", "Video" });
    // try csv_parser.addColumn("Good", &[_][]const u8{ "Games", "Video" });
    //csv_parser.displayTable();
    try csv_parser.removeColumn("label");
    //csv_parser.displayTable();
    // const newRow = [_][]const u8{ "Roshan", "27", "Zig is awesome!", "alice@example.com", "123-456-7890", "Software Engineer" };

    // try csv_parser.addRow(&newRow);

    // const result = try csv_parser.getColumnByName("Hobby");
    // defer result.deinit(); // Ensure the memory is properly deallocated after use

    // for (result.items) |item| {
    //     std.debug.print("Value: {s}\n", .{item});
    // }

     try csv_parser.writeCsv("test_two_file.csv");
}
