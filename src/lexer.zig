const token = @import("./token.zig");
const Token = token.Token;
const Kind = token.Kind;

const std = @import("std");

const KEYWORDS = [_]struct {
    literal: []const u8,
    kind: Kind,
}{
    .{ .literal = "fn", .kind = .Fn },
    .{ .literal = "let", .kind = .Let },
    .{ .literal = "true", .kind = .True },
    .{ .literal = "false", .kind = .False },
    .{ .literal = "if", .kind = .If },
    .{ .literal = "else", .kind = .Else },
    .{ .literal = "return", .kind = .Return },
};

fn lookupIdent(literal: []const u8) Kind {
    inline for (KEYWORDS) |k| {
        if (std.mem.eql(u8, k.literal, literal)) return k.kind;
    }

    return .Ident;
}

pub const Lexer = struct {
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
        self.skipWhitespace();

        return switch (self.ch) {
            '+' => self.char1(.Plus),
            '-' => self.char1(.Minus),
            '*' => self.char1(.Asterisk),
            '/' => self.char1(.Slash),

            '=' => if (self.peek() == '=') self.char2(.Eq) else self.char1(.Assign),
            '!' => if (self.peek() == '=') self.char2(.NEq) else self.char1(.Bang),
            '<' => if (self.peek() == '=') self.char2(.LEq) else self.char1(.LT),
            '>' => if (self.peek() == '=') self.char2(.GEq) else self.char1(.GT),

            ',' => self.char1(.Comma),
            ';' => self.char1(.Semicolon),

            '(' => self.char1(.Lparan),
            ')' => self.char1(.Rparan),
            '{' => self.char1(.Lbrace),
            '}' => self.char1(.Rbrace),

            '"' => self.readString(),

            0 => self.char0(.Eof),

            else => if (std.ascii.isAlphabetic(self.ch) or self.ch == '_')
                self.readIdent()
            else if (std.ascii.isDigit(self.ch))
                self.readNumber()
            else
                self.char1(.Illegal),
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

    fn readNumber(self: *Lexer) Token {
        const start = self.position;
        var kind: Kind = .Int;

        while (std.ascii.isDigit(self.ch)) : (self.readChar()) {}

        if (self.ch == '.') {
            kind = .Float;
            self.readChar();

            while (std.ascii.isDigit(self.ch)) : (self.readChar()) {}
        }

        return .{ .kind = kind, .literal = self.input[start..self.position] };
    }

    fn readIdent(self: *Lexer) Token {
        const start = self.position;
        while (std.ascii.isAlphanumeric(self.ch) or self.ch == '_') {
            self.readChar();
        }
        const literal = self.input[start..self.position];
        const kind = lookupIdent(literal);

        return .{ .kind = kind, .literal = literal };
    }

    fn readString(self: *Lexer) Token {
        const start = self.position;

        if (self.ch == '"') {
            self.readChar();

            while (self.ch != '"' and self.ch != 0) : (self.readChar()) {}
        }

        if (self.ch == '"') {
            self.readChar();
        }

        return .{ .kind = .String, .literal = self.input[start..self.position] };
    }

    fn peek(self: Lexer) u8 {
        return if (self.read_position < self.input.len) self.input[self.read_position] else 0;
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

    fn char2(self: *Lexer, k: Kind) Token {
        var tok = Token{ .kind = k, .literal = self.input[self.position .. self.position + 2] };
        self.readChar();
        self.readChar();
        return tok;
    }

    fn skipWhitespace(self: *Lexer) void {
        if (std.ascii.isWhitespace(self.ch)) {
            self.readChar();
        }
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

    test "comparison operator lexing" {
        const input = "=+-(){},;";
        var lexer = Lexer.new(input);

        const tests = [_]struct {
            expectedKind: Kind,
            expectedLiteral: []const u8,
        }{
            .{ .expectedKind = .Assign, .expectedLiteral = "=" },
            .{ .expectedKind = .Plus, .expectedLiteral = "+" },
            .{ .expectedKind = .Minus, .expectedLiteral = "-" },
            .{ .expectedKind = .Lparan, .expectedLiteral = "(" },
            .{ .expectedKind = .Rparan, .expectedLiteral = ")" },
            .{ .expectedKind = .Lbrace, .expectedLiteral = "{" },
            .{ .expectedKind = .Rbrace, .expectedLiteral = "}" },
            .{ .expectedKind = .Comma, .expectedLiteral = "," },
            .{ .expectedKind = .Semicolon, .expectedLiteral = ";" },
            .{ .expectedKind = .Eof, .expectedLiteral = "" },
        };

        var tok: Token = undefined;

        inline for (tests) |tt| {
            tok = lexer.nextToken();

            try testing.expectEqual(tt.expectedKind, tok.kind);
            try testing.expectEqualStrings(tt.expectedLiteral, tok.literal);
        }
    }
};
