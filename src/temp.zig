const std = @import("std");

const AllocatorExample = struct {
    allocator: std.mem.Allocator,
    array: ?[][]u32 = null,

    pub fn init(allocator: *const std.mem.Allocator) AllocatorExample {
        return AllocatorExample{
            .allocator = allocator.*,
            .array = null,
        };
    }

    pub fn create2DArray(self: *AllocatorExample, rows: usize, cols: usize) !void {
        // Ensure the array isn't already created
        if (self.array) |array| {
            for (array) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(array);
        }

        // Allocate space for the outer array (rows)
        self.array = try self.allocator.alloc([]u32, rows);

        // Allocate space for each row (columns)
        for (self.array.?) |*row| {
            row.* = try self.allocator.alloc(u32, cols);

            // Initialize the elements in the row
            var index: u32 = 0;
            for (row.*) |*value| {
                value.* = index;
                index += 1;
            }
        }
    }

    pub fn read2DArray(self: *AllocatorExample) void {
        if (self.array) |array| {
            var row_index: usize = 0;
            for (array) |row| {
                var col_index: usize = 0;
                for (row) |value| {
                    std.debug.print("array[{}][{}] = {}\n", .{row_index, col_index, value});
                    col_index += 1;
                }
                row_index += 1;
            }
        } else {
            std.debug.print("2D array is empty.\n", .{});
        }
    }

    pub fn deinit(self: *AllocatorExample) void {
        if (self.array) |array| {
            for (array) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(array);
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var example = AllocatorExample.init(&allocator); // Pass the allocator
    defer example.deinit();

    // Create and read a 2D array
    try example.create2DArray(3, 4); // 3 rows, 4 columns
    example.read2DArray();
}




// const std = @import("std");

// const CsvParser = struct {
//     allocator: std.mem.Allocator,
//     matrix: std.ArrayList(std.ArrayList([]const u8)),
//     headers: ?std.ArrayList([]const u8), // Optional field for storing headers

//     pub fn init(allocator: *const std.mem.Allocator) CsvParser {
//         return CsvParser{
//             .allocator = allocator.*,
//             .matrix = std.ArrayList(std.ArrayList([]const u8)).init(allocator.*),
//             .headers = null,
//         };
//     }

//     pub fn deinit(self: *CsvParser) void {
//         if (self.headers) |header_row| {
//             for (header_row.items) |header| {
//                 self.allocator.free(header);
//             }
//             header_row.deinit();
//         }

//         for (self.matrix.items) |row| {
//             for (row.items) |col| {
//                 self.allocator.free(col); // Free the memory for each column
//             }
//             row.deinit(); // Deallocates each row's memory
//         }
//         self.matrix.deinit(); // Deallocates the outer matrix
//     }

//     // pub fn readCsv(self: *CsvParser, path: []const u8, has_header: bool) !void {
//     //     const cwd = std.fs.cwd();
//     //     const file = try cwd.openFile(path, .{});
//     //     defer file.close();

//     //     const file_size = try file.getEndPos();
//     //     if (file_size == 0) {
//     //         return error.EmptyFile; // Define an appropriate error type
//     //     }
//     //     var buffer = try self.allocator.alloc(u8, file_size);
//     //     defer self.allocator.free(buffer);

//     //     _ = try file.readAll(buffer);

//     //     // Check for BOM and skip if present
//     //     var content: []const u8 = buffer[0..];
//     //     if (content.len >= 3 and std.mem.eql(u8, content[0..3], "\xEF\xBB\xBF")) {
//     //         content = content[3..]; // Skip the BOM
//     //     }

//     //     // Split rows by newline
//     //     var rows = std.mem.splitSequence(u8, content, "\n");

//     //     var is_first_row = true;

//     //     while (rows.next()) |row| {
//     //         var row_data = std.ArrayList([]const u8).init(self.allocator);
//     //         var cols = std.mem.splitSequence(u8, row, ",");

//     //         while (cols.next()) |col| {
//     //             const copied_col = try self.allocator.alloc(u8, col.len);
//     //             std.mem.copyForwards(u8, copied_col, col);
//     //             try row_data.append(copied_col[0..]);
//     //         }

//     //         if (is_first_row and has_header) {
//     //             self.headers = row_data;
//     //         } else {
//     //             try self.matrix.append(row_data);
//     //         }

//     //         is_first_row = false;

//     //     }
//     // }

//     // pub fn displayAll(self: *CsvParser) void {
//     //     if (self.matrix.items.len == 0) {
//     //         std.log.info("Matrix is empty.", .{});
//     //         return;
//     //     }

//     //     var row_index: usize = 0;
//     //     for (self.matrix.items) |row| {
//     //         std.debug.print("Row {d}:\n", .{row_index});
//     //         var col_index: usize = 0;
//     //         for (row.items) |value| {
//     //             std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
//     //             col_index += 1;
//     //         }

//     //         row_index += 1;
//     //     }
//     // }

//     // pub fn getValue(self: *CsvParser, row: usize, col: usize) ?[]const u8 {
//     //     if (row < self.matrix.items.len and col < self.matrix.items[row].items.len) {
//     //         return self.matrix.items[row].items[col];
//     //     }
//     //     return null; // Return `null` if the indices are out of bounds
//     // }

//     // pub fn displayHead(self: *CsvParser, n: usize) void {
//     //     const total_rows = self.matrix.items.len;

//     //     if (total_rows == 0) {
//     //         std.log.info("Matrix is empty. Nothing to display.", .{});
//     //         return;
//     //     }

//     //     const display_count = if (n < total_rows) n else total_rows;
//     //     std.log.info("Displaying first {d} row(s):", .{display_count});

//     //     var row_index: usize = 0;
//     //     for (self.matrix.items[0..display_count]) |row| {
//     //         std.debug.print("Row {d}:\n", .{row_index});
//     //         row_index += 1;

//     //         var col_index: usize = 0;
//     //         for (row.items) |value| {
//     //             std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
//     //             col_index += 1;
//     //         }
//     //     }
//     // }

//     // pub fn displayTail(self: *CsvParser, n: usize) void {
//     //     const total_rows = self.matrix.items.len;

//     //     if (total_rows == 0) {
//     //         std.log.info("Matrix is empty. Nothing to display.", .{});
//     //         return;
//     //     }

//     //     const display_count = if (n < total_rows) n else total_rows;
//     //     const start_index = total_rows - display_count;

//     //     std.log.info("Displaying last {d} row(s):", .{display_count});

//     //     var row_index: usize = start_index;
//     //     for (self.matrix.items[start_index..total_rows]) |row| {
//     //         std.debug.print("Row {d}:\n", .{row_index});
//     //         row_index += 1;

//     //         var col_index: usize = 0;
//     //         for (row.items) |value| {
//     //             std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
//     //             col_index += 1;
//     //         }
//     //     }
//     // }

//     // pub fn displayColumn(self: *CsvParser, col: usize) void {
//     //     const total_rows = self.matrix.items.len;

//     //     if (total_rows == 0) {
//     //         std.log.info("Matrix is empty. No columns to display.", .{});
//     //         return;
//     //     }

//     //     std.log.info("Displaying column {d}:", .{col});

//     //     var row_index: usize = 0;
//     //     for (self.matrix.items) |row| {
//     //         if (col < row.items.len) {
//     //             std.debug.print("Row {d}: {s}\n", .{ row_index, row.items[col] });
//     //         } else {
//     //             std.debug.print("Row {d}: (Out of Bounds)\n", .{row_index});
//     //         }
//     //         row_index += 1;
//     //     }
//     // }

//     // pub fn displayHeaders(self: *CsvParser) void {
//     //     if (self.headers == null) {
//     //         std.log.info("No headers found.", .{});
//     //         return;
//     //     }

//     //     std.log.info("Headers:", .{});
//     //     var col_index: usize = 0;
//     //     for (self.headers.?.items) |header| {
//     //         std.debug.print("  Column {d}: {s}\n", .{ col_index, header });
//     //         col_index += 1;
//     //     }
//     // }

//     // pub fn getColumnByName(self: *CsvParser, column_name: []const u8) !?[]const []const u8 {
//     //     // if (!self.has_header) {
//     //     //     std.log.err("CSV does not have headers. Cannot search by column name.", .{});
//     //     //     return null;
//     //     // }

//     //     // Find the index of the column name in headers
//     //     var column_index: usize = undefined;
//     //     var index: usize = 0;
//     //     for (self.headers.?.items) |header| {
//     //         if (std.mem.eql(u8, header, column_name)) {
//     //             column_index = index;
//     //             break;
//     //         }

//     //         index += 1;
//     //     }

//     //     if (column_index == undefined) {
//     //         std.log.err("Column name '{s}' not found in headers.", .{column_name});
//     //         return null;
//     //     }

//     //     // Allocate an array for column values
//     //     //var column_values = try self.allocator.alloc([]const u8, self.matrix.items.len);
//     //     //defer self.allocator.free(column_values);
//     //     const rows_count = self.matrix.items.len;
//     //     var column_values: [rows_count]?[]const u8 = undefined;

//     //     var row_index: usize = 0;

//     //     // Extract the values for the column
//     //     for (self.matrix.items) |row| {
//     //         if (column_index < row.items.len) {
//     //             column_values[row_index] = row.items[column_index];
//     //         } else {
//     //             column_values[row_index] = null; // Handle missing values gracefully
//     //         }
//     //         row_index += 1;
//     //     }

//     //     return column_values;
//     // }

//     pub fn getColumnByName(self: *CsvParser, column_name: []const u8) void {
//         std.debug.print("No headers available. Cannot find column '{s}'.", .{column_name});
//         std.debug.print("No headers available. Cannot find column '{}'.", .{self.allocator});
//         var list = std.ArrayList([]const u8).init(self.allocator);

//         defer list.deinit();

//         try list.append("Hello"[0..]);

//         // if (self.headers == null) {
//         //     std.log.err("No headers available. Cannot find column '{s}'.", .{column_name});
//         //     return;
//         // }

//         // // Find the column index
//         // var column_index: usize = 0;
//         // var idx: usize = 0;
//         // for (self.headers.?.items) |header| {
//         //     if (std.mem.eql(u8, header, column_name)) {
//         //         column_index = idx;
//         //         break;
//         //     }
//         //     idx += 1;
//         // }

//         // if (column_index == 0) {
//         //     std.log.err("Column '{s}' not found in headers.", .{column_name});
//         //     return;
//         // }

//         // // Print column data
//         // std.log.info("Data for column '{s}':", .{column_name});
//         // std.log.info("Length of columns {}", .{self.matrix.items.len});
//         // var list = std.ArrayList([]const u8).init(self.allocator);

//         // defer list.deinit();

//         // std.debug.print("Capacity {}\n", .{list.capacity});

//         // for (self.matrix.items) |row| {
//         //     if (column_index >= row.items.len) {
//         //         std.log.warn("Row is missing data for column '{s}'.", .{column_name});
//         //         continue;
//         //     }
//         //     const col_data = row.items[column_index];
//         //     std.debug.print("{s}\n", .{col_data});

//         //     //try list.append(col_data);

//         // }
//     }
// };

// pub fn main() !void {
//     const allocator = std.heap.page_allocator;
//     var csv_parser = CsvParser.init(&allocator);
//     //defer csv_parser.deinit();
//     // try csv_parser.readCsv("Book1.csv", true);
//     // std.debug.print("Reading completed", .{});

//     csv_parser.getColumnByName("city");
// }

