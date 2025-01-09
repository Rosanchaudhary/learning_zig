const std = @import("std");

const CsvParser = struct {
    allocator: std.mem.Allocator,
    matrix: std.ArrayList(std.ArrayList([]const u8)),

    pub fn init(allocator: *const std.mem.Allocator) CsvParser {
        return CsvParser{
            .allocator = allocator.*,
            .matrix = std.ArrayList(std.ArrayList([]const u8)).init(allocator.*),
        };
    }

    pub fn deinit(self: *CsvParser) void {
        for (self.matrix.items) |row| {
            for (row.items) |col| {
                self.allocator.free(col); // Free the memory for each column
            }
            //             for (row.items) |col| {
            //     self.allocator.free(col.ptr); // Free each column
            // }
            std.debug.print("Deinitializing row with {d} columns.\n", .{row.items.len});
            row.deinit(); // Deallocates each row's memory
        }
        self.matrix.deinit(); // Deallocates the outer matrix
    }

    pub fn readCsv(self: *CsvParser, path: []const u8) !void {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile(path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        var buffer = try self.allocator.alloc(u8, file_size);
        defer self.allocator.free(buffer);

        _ = try file.readAll(buffer);

        // Check for BOM and skip if present
        var content: []const u8 = buffer[0..];
        if (content.len >= 3 and std.mem.eql(u8, content[0..3], "\xEF\xBB\xBF")) {
            content = content[3..]; // Skip the BOM
        }

        // Split rows by newline
        var rows = std.mem.splitSequence(u8, content, "\n");

        while (rows.next()) |row| {
            var row_data = std.ArrayList([]const u8).init(self.allocator);

            // Split the row by commas to get columns
            var cols = std.mem.splitSequence(u8, row, ",");
            while (cols.next()) |col| {
                const copied_col = try self.allocator.alloc(u8, col.len);
                std.mem.copyForwards(u8, copied_col, col);
                try row_data.append(copied_col[0..]); // Use the slice from the copied array

                // try row_data.append(col);
            }

            // Add the completed row to the matrix
            try self.matrix.append(row_data);
            std.debug.print("Row appended, matrix size: {d}\n", .{self.matrix.items.len});
        }

        std.debug.print("The value in read {s}\n", .{self.matrix.items[0].items[0]});
    }

    pub fn printValue(self: *CsvParser, row: usize, col: usize) void {
        if (row < self.matrix.items.len and col < self.matrix.items[row].items.len) {
            const value = self.matrix.items[row].items[col];
            // Use allocator-independent debug output
            std.log.info("Matrix element: {s}", .{value});
        } else {
            std.log.err("Index out of bounds: row={d}, col={d}", .{ row, col });
        }
    }

    pub fn displayAll(self: *CsvParser) void {
        const value = self.matrix.items[0].items[2];
        std.debug.print("The value at matrix is here motherfucker {s}:\n", .{value});
        // if (self.matrix.items.len == 0) {
        //     std.log.info("Matrix is empty.", .{});
        //     return;
        // }

        // var row_index : usize  = 0;
        // for (self.matrix.items) |row| {
        //     std.debug.print("Row {d}:\n", .{row_index});
        //     var col_index : usize  =0;
        //     for (row.items) |value| {
        //         std.debug.print("  Column {d}: {s}\n", .{col_index, value});
        //         col_index += 1;
        //     }

        //     row_index +=1;
        // }
    }

    pub fn getValue(self: *CsvParser, row: usize, col: usize) ?[]const u8 {
        if (row < self.matrix.items.len and col < self.matrix.items[row].items.len) {
            return self.matrix.items[row].items[col];
        }
        return null; // Return `null` if the indices are out of bounds
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var csv_parser = CsvParser.init(&allocator);
    defer csv_parser.deinit();
    try csv_parser.readCsv("Book1.csv");

    // Example: Print element at row 1, column 0
    //csv_parser.printValue(1, 0);

    csv_parser.displayAll();
    //std.debug.print("displaying CSV file: {s}\n", .{"mnist_test.csv"});

    // Example: Retrieve and display the value at row 0, column 1
    if (csv_parser.getValue(0, 1)) |value| {
        std.debug.print("Value at (0, 1): {s}\n", .{value});
    } else {
        std.debug.print("Value at (0, 1) not found or out of bounds.\n", .{});
    }
}
