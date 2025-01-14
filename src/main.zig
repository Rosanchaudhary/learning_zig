const std = @import("std");
pub const CsvParser = @import("CsvParser.zig").CsvParser;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var csv_parser = CsvParser.init(&allocator);
    defer csv_parser.deinit();

    try csv_parser.readCsv("Book1.csv", true);


}
