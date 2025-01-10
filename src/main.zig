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
            row.deinit(); // Deallocates each row's memory
        }
        self.matrix.deinit(); // Deallocates the outer matrix
    }

    pub fn readCsv(self: *CsvParser, path: []const u8) !void {
        const cwd = std.fs.cwd();
        const file = try cwd.openFile(path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        if (file_size == 0) {
            return error.EmptyFile; // Define an appropriate error type
        }
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
            // Allocate a single buffer for the entire row
            const row_buffer = try self.allocator.alloc(u8, row.len);
            defer self.allocator.free(row_buffer);

            std.mem.copyForwards(u8, row_buffer, row);

            // Split the row into columns
            var row_data = std.ArrayList([]const u8).init(self.allocator);
            var cols = std.mem.splitSequence(u8, row_buffer, ",");
            while (cols.next()) |col| {

                // Allocate memory for each column's data
                const copied_col = try self.allocator.alloc(u8, col.len);

                // Copy the column's data into the newly allocated memory
                std.mem.copyForwards(u8, copied_col, col);

                // Append the slice of the copied array to row_data
                try row_data.append(copied_col[0..]);
                //try row_data.append(col); // Use slices from the preallocated buffer
            }

            // Add the row to the matrix
            try self.matrix.append(row_data);
        }
    }

    pub fn displayAll(self: *CsvParser) void {
        if (self.matrix.items.len == 0) {
            std.log.info("Matrix is empty.", .{});
            return;
        }

        var row_index: usize = 0;
        for (self.matrix.items) |row| {
            std.debug.print("Row {d}:\n", .{row_index});
            var col_index: usize = 0;
            for (row.items) |value| {
                std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
                col_index += 1;
            }

            row_index += 1;
        }
    }

    pub fn getValue(self: *CsvParser, row: usize, col: usize) ?[]const u8 {
        if (row < self.matrix.items.len and col < self.matrix.items[row].items.len) {
            return self.matrix.items[row].items[col];
        }
        return null; // Return `null` if the indices are out of bounds
    }

    pub fn displayHead(self: *CsvParser, n: usize) void {
        const total_rows = self.matrix.items.len;

        if (total_rows == 0) {
            std.log.info("Matrix is empty. Nothing to display.", .{});
            return;
        }

        const display_count = if (n < total_rows) n else total_rows;
        std.log.info("Displaying first {d} row(s):", .{display_count});

        var row_index: usize = 0;
        for (self.matrix.items[0..display_count]) |row| {
            std.debug.print("Row {d}:\n", .{row_index});
            row_index += 1;

            var col_index: usize = 0;
            for (row.items) |value| {
                std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
                col_index += 1;
            }
        }
    }

    pub fn displayTail(self: *CsvParser, n: usize) void {
        const total_rows = self.matrix.items.len;

        if (total_rows == 0) {
            std.log.info("Matrix is empty. Nothing to display.", .{});
            return;
        }

        const display_count = if (n < total_rows) n else total_rows;
        const start_index = total_rows - display_count;

        std.log.info("Displaying last {d} row(s):", .{display_count});

        var row_index: usize = start_index;
        for (self.matrix.items[start_index..total_rows]) |row| {
            std.debug.print("Row {d}:\n", .{row_index});
            row_index += 1;

            var col_index: usize = 0;
            for (row.items) |value| {
                std.debug.print("  Column {d}: {s}\n", .{ col_index, value });
                col_index += 1;
            }
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var csv_parser = CsvParser.init(&allocator);
    defer csv_parser.deinit();
    try csv_parser.readCsv("Book1.csv");
    std.debug.print("Reading completed", .{});

    csv_parser.displayTail(1);
    // Example: Retrieve and display the value at row 0, column 1
    if (csv_parser.getValue(0, 2)) |value| {
        std.debug.print("Value at (0, 1): {s}\n", .{value});
    } else {
        std.debug.print("Value at (0, 1) not found or out of bounds.\n", .{});
    }
}
