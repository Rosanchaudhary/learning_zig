const std = @import("std");

const CsvParserErrors = error{
    NoHeadersAvailable,
    ColumnNotFound,
};

pub const CsvParser = struct {
    allocator: std.mem.Allocator,
    matrix: std.ArrayList(std.ArrayList([]const u8)),
    headers: ?std.ArrayList([]const u8), // Optional field for storing headers

    pub fn init(allocator: *const std.mem.Allocator) CsvParser {
        return CsvParser{
            .allocator = allocator.*,
            .matrix = std.ArrayList(std.ArrayList([]const u8)).init(allocator.*),
            .headers = null,
        };
    }

    pub fn readCsv(self: *CsvParser, path: []const u8, has_header: bool) !void {
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

        var is_first_row = true;

        while (rows.next()) |row| {
            var row_data = std.ArrayList([]const u8).init(self.allocator);
            var cols = std.mem.splitSequence(u8, row, ",");

            while (cols.next()) |col| {
                const copied_col = try self.allocator.alloc(u8, col.len);
                std.mem.copyForwards(u8, copied_col, col);
                try row_data.append(copied_col[0..]);
            }

            if (is_first_row and has_header) {
                self.headers = row_data;
            } else {
                try self.matrix.append(row_data);
            }

            is_first_row = false;
        }
    }

    pub fn getColumnByName(self: *CsvParser, column_name: []const u8) !std.ArrayList([]const u8) {
        if (self.headers == null) {
            std.log.err("No headers available. Cannot find column '{s}'.", .{column_name});
            return error.NoHeadersAvailable; // Define an appropriate error type
        }

        // Find the column index
        var column_index: i32 = -1;
        var idx: i32 = 0;
        for (self.headers.?.items) |header| {
            if (std.mem.eql(u8, header, column_name)) {
                column_index = idx;
                break;
            }
            idx += 1;
        }

        if (column_index == -1) {
            std.log.err("Column '{s}' not found in headers.", .{column_name});
            return error.ColumnNotFound; // Define an appropriate error type
        }

        var list = std.ArrayList([]const u8).init(self.allocator);

        //defer list.deinit();

        for (self.matrix.items) |row| {
            if (column_index >= row.items.len) {
                std.log.warn("Row is missing data for column '{s}'.", .{column_name});
                continue;
            }
            const column_index_usize: usize = @intCast(column_index);
            const col_data = row.items[column_index_usize];

            try list.append(col_data);
        }

        return list;
    }

    pub fn displayHeaders(self: *CsvParser) void {
        if (self.headers == null) {
            std.log.info("No headers found.", .{});
            return;
        }

        std.log.info("Headers:", .{});
        var col_index: usize = 0;
        for (self.headers.?.items) |header| {
            std.debug.print("Header {d}: {s}\n", .{ col_index, header });
            col_index += 1;
        }
    }

    pub fn addRow(self: *CsvParser, new_row: []const []const u8) !void {
        var row_data = std.ArrayList([]const u8).init(self.allocator);
        // defer row_data.deinit();

        for (new_row) |col| {
            const copied_col = try self.allocator.alloc(u8, col.len);
            std.mem.copyForwards(u8, copied_col, col);
            try row_data.append(copied_col[0..]);
        }

        try self.matrix.append(row_data);
    }

    pub fn addColumn(self: *CsvParser, column_name: []const u8, values: []const []const u8) !void {
        if (self.headers == null) {
            self.headers = std.ArrayList([]const u8).init(self.allocator);
        }

        std.debug.print("The column name {s}", .{column_name});

        try self.headers.?.append(column_name);

        if (values.len != self.matrix.items.len) {
            return error.InvalidColumnLength; // Define this error
        }

        var idx: usize = 0;

        for (self.matrix.items) |_| {
            try self.matrix.items[idx].append(values[idx]);
            idx += 1;
        }
    }

    pub fn removeColumn(self: *CsvParser, column_name: []const u8) !void {
        if (self.headers == null) {
            return error.NoHeadersAvailable; // Ensure headers exist
        }

        // Find the column index
        var column_index: i32 = -1;
        var idx: i32 = 0;
        for (self.headers.?.items) |header| {
            if (std.mem.eql(u8, header, column_name)) {
                column_index = idx;
                break;
            }
            idx += 1;
        }

        if (column_index == -1) {
            return error.ColumnNotFound; // Column does not exist
        }

        // Remove column from headers
        const column_index_usize: usize = @intCast(column_index);
        _ = self.headers.?.orderedRemove(column_index_usize);

        // Remove column from each row in the matrix
        for (self.matrix.items) |*row| { // Make `row` mutable
            if (column_index_usize < row.items.len) {
                _ = row.orderedRemove(column_index_usize);
            }
        }
    }

    pub fn writeCsv(self: *CsvParser, path: []const u8) !void {
        const cwd = std.fs.cwd();
        var file = try cwd.createFile(path, .{ .truncate = true });
        defer file.close();

        if (self.headers != null) {
            var idx: usize = 0;
            for (self.headers.?.items) |header| {
                std.debug.print("{s} \t", .{header});
                if (idx != 0) try file.writeAll(",");
                try file.writeAll(header);
                idx += 1;
            }
        }

        // var line = std.ArrayList(u8).init(self.allocator);
        // defer line.deinit();

        // var i: usize = 0;
        // for (self.headers.?.items) |col| {
        //     if (i != 0) try line.append(',');
        //     try line.appendSlice(col);
        //     i += 1;
        // }
        // try line.appendSlice("\n");

        // try file.writeAll(line.items);

        for (self.matrix.items) |row| {
            var idx: usize = 0;
            for (row.items) |col| {
                if (idx != 0) try file.writeAll(",");
                try file.writeAll(col);
                idx += 1;
            }
            try file.writeAll("\n");
        }
    }

    pub fn displayTable(self: *CsvParser) void {
        // Display the initial table
        std.debug.print("Initial Table Data:\n", .{});
        for (self.matrix.items) |row| {
            for (row.items) |col| {
                std.debug.print("The value of table {s} \n", .{col});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn deinit(self: *CsvParser) void {
        if (self.headers) |header_row| {
            // for (header_row.items) |header| {

            //     self.allocator.free(header);
            // }
            header_row.deinit();
        }

        for (self.matrix.items) |row| {
            // for (row.items) |col| {
            //     self.allocator.free(col); // Free the memory for each column
            // }
            row.deinit(); // Deallocates each row's memory
        }
        self.matrix.deinit(); // Deallocates the outer matrix
    }
};
