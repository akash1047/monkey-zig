const std = @import("std");
const token = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;

const print = std.debug.print;

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    const reader = stdin.reader();
    const writer = stdout.writer();

    var bufWriter = std.io.bufferedWriter(writer);

    var buf: [100]u8 = undefined;

    try writer.print("monkey repel\n", .{});
    try bufWriter.flush();

    while (true) {
        try writer.print("> ", .{});
        const l = try reader.read(buf[0..]);
        const input = buf[0..l];

        var lexer = Lexer.new(input);

        var tok = lexer.nextToken();
        while (tok.kind != .eof) : (tok = lexer.nextToken()) {
            try writer.print("Token( kind={}, value=\"{s}\" )\n", .{ tok.kind, tok.span });
        }

        try bufWriter.flush();
    }
}
