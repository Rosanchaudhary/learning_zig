const std = @import("std");

pub fn main() !void {
    const width: u32 = 100;
    const height: u32 = 100;

    const png_signature = &[_]u8{ 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A };

    const file = try std.fs.cwd().createFile("output.png", .{});
    defer file.close();

    // Write PNG signature
    try file.writeAll(png_signature);

    // Write IHDR chunk
    const ihdr_data = &[_]u8{
        @as(u8, (width >> 24) & 0xFF),
        @as(u8, (width >> 16) & 0xFF),
        @as(u8, (width >> 8) & 0xFF),
        @as(u8, width & 0xFF),
        @as(u8, (height >> 24) & 0xFF),
        @as(u8, (height >> 16) & 0xFF),
        @as(u8, (height >> 8) & 0xFF),
        @as(u8, height & 0xFF),
        8,  // Bit depth
        2,  // Color type (truecolor)
        0,  // Compression method
        0,  // Filter method
        0,  // Interlace method
    };
    try writeChunk(file, "IHDR", ihdr_data);

    // Prepare image data
    const row_size = 1 + 3 * width;
    var raw_data = try std.heap.page_allocator.alloc(u8, row_size * height);
    defer std.heap.page_allocator.free(raw_data);

    for (0..height) |row_idx| {
        const offset = row_idx * row_size;
        raw_data[offset] = 0; // Filter type: none
        for (0..width) |col_idx| {
            const pixel_offset = offset + 1 + 3 * col_idx;
            raw_data[pixel_offset] = 255; // Red
            raw_data[pixel_offset + 1] = 0; // Green
            raw_data[pixel_offset + 2] = 0; // Blue
        }
    }

    // Write IDAT chunk with uncompressed raw data
    try writeChunk(file, "IDAT", raw_data);

    // Write IEND chunk
    try writeChunk(file, "IEND", &[_]u8{});
}

fn writeChunk(file: anytype, name: []const u8, data: []const u8) !void {
    const data_len = @as(u32, data.len); // Explicitly cast data length to u32
    var crc32 = std.hash.Crc32.init();
    const length_bytes = u32ToBytes(data_len);

    try file.writeAll(length_bytes); // Chunk length
    try file.writeAll(name);        // Chunk name
    try file.writeAll(data);        // Chunk data

    crc32.update(name);
    crc32.update(data);

    const crc_bytes = u32ToBytes(crc32.final());
    try file.writeAll(crc_bytes);   // CRC
}

fn u32ToBytes(value: u32) []u8 {
    return [_]u8{
        @as(u8, (value >> 24) & 0xFF),
        @as(u8, (value >> 16) & 0xFF),
        @as(u8, (value >> 8) & 0xFF),
        @as(u8, value & 0xFF),
    };
}