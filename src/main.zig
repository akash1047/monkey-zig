const std = @import("std");
const token = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;
const repel = @import("repel.zig");

const print = std.debug.print;

pub fn main() !void {
    print("monkey programming language\n", .{});

    const rl = repel.NewRepel(100);

    while (true) {
        const input = if (rl.readLine("> ")) |val| val else |err| {
            switch (err) {
                repel.InputError.EndOfFile => print("CTRL-D\n", .{}),
                repel.InputError.Interrupt => print("CTRL-C\n", .{}),
                else => |e| print("repel error: {}\n", .{e}),
            }
            break;
        };

        var lexer = Lexer.new(input);

        var tok = lexer.nextToken();
        while (tok.kind != .eof) : (tok = lexer.nextToken()) {
            print("Token( kind={}, value=\"{s}\" )\n", .{ tok.kind, tok.span });
        }
    }
}
