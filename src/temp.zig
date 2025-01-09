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

