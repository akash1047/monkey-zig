const token = @import("./token.zig");
const Token = token.Token;
const Kind = token.Kind;

const std = @import("std");
const testing = std.testing;

const Lexer = struct {
    input: []const u8,

    position: usize,
    read_position: usize,
    ch: u8,

    pub fn new(input: []const u8) Lexer {
        var l = Lexer{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0,
        };

        l.read_char();

        return l;
    }

    fn read_char(self: *Lexer) void {
        if (self.read_position < self.input.len) {
            self.ch = self.input[self.read_position];
            self.position = self.read_position;
        } else {
            self.ch = 0;
            self.position = self.input.len;
        }

        self.read_position += 1;
    }
};

test {
    _ = LexerStateTest;
}

const LexerStateTest = struct {
    const expectEqual = @import("std").testing.expectEqual;

    test "Lexer state on calling read_char" {
        var lexer = Lexer.new("x = 5;");

        try expectEqual(@intCast(usize, 0), lexer.position);
        try expectEqual(@intCast(usize, 1), lexer.read_position);
        try expectEqual(@intCast(u8, 'x'), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 1), lexer.position);
        try expectEqual(@intCast(usize, 2), lexer.read_position);
        try expectEqual(@intCast(u8, ' '), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 2), lexer.position);
        try expectEqual(@intCast(usize, 3), lexer.read_position);
        try expectEqual(@intCast(u8, '='), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 3), lexer.position);
        try expectEqual(@intCast(usize, 4), lexer.read_position);
        try expectEqual(@intCast(u8, ' '), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 4), lexer.position);
        try expectEqual(@intCast(usize, 5), lexer.read_position);
        try expectEqual(@intCast(u8, '5'), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 5), lexer.position);
        try expectEqual(@intCast(usize, 6), lexer.read_position);
        try expectEqual(@intCast(u8, ';'), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 7), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 8), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 9), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.read_char();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 10), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);
    }
};
