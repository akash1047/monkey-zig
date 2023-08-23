const token = @import("./token.zig");
const Token = token.Token;
const Kind = token.Kind;

const std = @import("std");

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

        l.readChar();

        return l;
    }

    pub fn nextToken(self: *Lexer) Token {
        return switch (self.ch) {
            '+' => self.char1(.Plus),
            '-' => self.char1(.Minus),
            '*' => self.char1(.Asterisk),
            '/' => self.char1(.Slash),
            0 => self.char0(.Eof),

            else => self.char1(.Illegal),
        };
    }

    fn readChar(self: *Lexer) void {
        if (self.read_position < self.input.len) {
            self.ch = self.input[self.read_position];
            self.position = self.read_position;
        } else {
            self.ch = 0;
            self.position = self.input.len;
        }

        self.read_position += 1;
    }

    fn char0(self: *Lexer, k: Kind) Token {
        var tok = Token{ .kind = k, .literal = self.input[self.position..self.position] };
        return tok;
    }

    fn char1(self: *Lexer, k: Kind) Token {
        var tok = Token{ .kind = k, .literal = self.input[self.position .. self.position + 1] };
        self.readChar();
        return tok;
    }
};

test {
    _ = LexerStateTest;
    _ = LexingTest;
}

const LexerStateTest = struct {
    const expectEqual = @import("std").testing.expectEqual;

    test "Lexer state on calling readChar" {
        var lexer = Lexer.new("x = 5;");

        try expectEqual(@intCast(usize, 0), lexer.position);
        try expectEqual(@intCast(usize, 1), lexer.read_position);
        try expectEqual(@intCast(u8, 'x'), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 1), lexer.position);
        try expectEqual(@intCast(usize, 2), lexer.read_position);
        try expectEqual(@intCast(u8, ' '), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 2), lexer.position);
        try expectEqual(@intCast(usize, 3), lexer.read_position);
        try expectEqual(@intCast(u8, '='), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 3), lexer.position);
        try expectEqual(@intCast(usize, 4), lexer.read_position);
        try expectEqual(@intCast(u8, ' '), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 4), lexer.position);
        try expectEqual(@intCast(usize, 5), lexer.read_position);
        try expectEqual(@intCast(u8, '5'), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 5), lexer.position);
        try expectEqual(@intCast(usize, 6), lexer.read_position);
        try expectEqual(@intCast(u8, ';'), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 7), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 8), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 9), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);

        lexer.readChar();
        try expectEqual(@intCast(usize, 6), lexer.position);
        try expectEqual(@intCast(usize, 10), lexer.read_position);
        try expectEqual(@intCast(u8, 0), lexer.ch);
    }
};

const LexingTest = struct {
    const testing = @import("std").testing;

    test "arithmatic operator lexing" {
        var lexer = Lexer.new("+-*/");

        var tok = lexer.nextToken();
        try testing.expectEqual(Kind.Plus, tok.kind);
        try testing.expectEqualStrings("+", tok.literal);

        tok = lexer.nextToken();
        try testing.expectEqual(Kind.Minus, tok.kind);
        try testing.expectEqualStrings("-", tok.literal);

        tok = lexer.nextToken();
        try testing.expectEqual(Kind.Asterisk, tok.kind);
        try testing.expectEqualStrings("*", tok.literal);

        tok = lexer.nextToken();
        try testing.expectEqual(Kind.Slash, tok.kind);
        try testing.expectEqualStrings("/", tok.literal);

        tok = lexer.nextToken();
        try testing.expectEqual(Kind.Eof, tok.kind);
        try testing.expectEqualStrings("", tok.literal);
    }
};
