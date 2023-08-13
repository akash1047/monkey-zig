const token = @import("./token.zig");
const Token = token.Token;
const Kind = token.Kind;

const std = @import("std");
const testing = std.testing;

pub const Lexer = struct {
    source: []const u8,
    position: usize,
    read_position: usize,
    ch: u8,

    pub fn new(source: []const u8) Lexer {
        var lexer: Lexer = .{
            .source = source,
            .position = 0,
            .read_position = 0,
            .ch = 0,
        };

        lexer.readChar();

        return lexer;
    }

    pub fn nextToken(self: *Lexer) Token {
        var tok: Token = undefined;
        self.skipWhitespace();

        switch (self.ch) {
            '=' => tok = .{ .kind = Kind.assign, .span = self.source[self.position .. self.position + 1] },
            ';' => tok = .{ .kind = Kind.semicolon, .span = self.source[self.position .. self.position + 1] },
            '(' => tok = .{ .kind = Kind.leftParenthesis, .span = self.source[self.position .. self.position + 1] },
            ')' => tok = .{ .kind = Kind.rightParenthesis, .span = self.source[self.position .. self.position + 1] },
            ',' => tok = .{ .kind = Kind.comma, .span = self.source[self.position .. self.position + 1] },
            '+' => tok = .{ .kind = Kind.plus, .span = self.source[self.position .. self.position + 1] },
            '{' => tok = .{ .kind = Kind.leftBrace, .span = self.source[self.position .. self.position + 1] },
            '}' => tok = .{ .kind = Kind.rightBrace, .span = self.source[self.position .. self.position + 1] },
            0 => tok = .{ .kind = Kind.eof, .span = "" },
            else => {
                if (isLetter(self.ch)) {
                    tok.span = self.readIdentifier();
                    tok.kind = lookupIdent(tok.span);
                    return tok;
                } else if (isDigit(self.ch)) {
                    tok.kind = .intLiteral;
                    tok.span = self.readNumber();
                    return tok;
                } else {
                    tok = .{ .kind = Kind.illegal, .span = self.source[self.position..] };
                }
            },
        }

        self.readChar();

        return tok;
    }

    fn readChar(self: *Lexer) void {
        self.ch = if (self.read_position < self.source.len)
            self.source[self.read_position]
        else
            0;

        self.position = self.read_position;
        self.read_position += 1;
    }

    fn readIdentifier(self: *Lexer) []const u8 {
        const position = self.position;

        while (isLetter(self.ch)) : (self.readChar()) {}

        return self.source[position..self.position];
    }

    fn skipWhitespace(self: *Lexer) void {
        while (std.ascii.isWhitespace(self.ch)) : (self.readChar()) {}
    }

    fn readNumber(self: *Lexer) []const u8 {
        const position = self.position;

        while (isDigit(self.ch)) : (self.readChar()) {} else return self.source[position..self.position];
    }
};

fn isLetter(ch: u8) bool {
    return std.ascii.isAlphabetic(ch) or ch == '_';
}

fn lookupIdent(ident: []const u8) Kind {
    const keywords = [_]struct {
        literal: []const u8,
        kind: Kind,
    }{
        .{ .literal = "fn", .kind = .fnKeyword },
        .{ .literal = "let", .kind = .letKeyword },
    };

    for (keywords) |k| if (std.mem.indexOfDiff(u8, k.literal, ident) == null) return k.kind;
    return .ident;
}

fn isDigit(ch: u8) bool {
    return std.ascii.isDigit(ch);
}

test "lexer nextToken function test on string `=+(){},;`" {
    const input = "=+(){},;";

    const tests = [_]struct {
        expected_type: Kind,
        expected_literal: []const u8,
    }{
        .{ .expected_type = Kind.assign, .expected_literal = "=" },
        .{ .expected_type = Kind.plus, .expected_literal = "+" },
        .{ .expected_type = Kind.leftParenthesis, .expected_literal = "(" },
        .{ .expected_type = Kind.rightParenthesis, .expected_literal = ")" },
        .{ .expected_type = Kind.leftBrace, .expected_literal = "{" },
        .{ .expected_type = Kind.rightBrace, .expected_literal = "}" },
        .{ .expected_type = Kind.comma, .expected_literal = "," },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.eof, .expected_literal = "" },
    };

    var lexer = Lexer.new(input);

    inline for (tests) |tt| {
        const tok = lexer.nextToken();
        try testing.expectEqual(tt.expected_type, tok.kind);
        try testing.expectEqualStrings(tt.expected_literal, tok.span);
    }
}

test "lexing source" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\
        \\let result = add(five, ten);
        \\
    ;

    const tests = [_]struct {
        expected_type: Kind,
        expected_literal: []const u8,
    }{
        .{ .expected_type = Kind.letKeyword, .expected_literal = "let" },
        .{ .expected_type = Kind.ident, .expected_literal = "five" },
        .{ .expected_type = Kind.assign, .expected_literal = "=" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "5" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },

        .{ .expected_type = Kind.letKeyword, .expected_literal = "let" },
        .{ .expected_type = Kind.ident, .expected_literal = "ten" },
        .{ .expected_type = Kind.assign, .expected_literal = "=" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },

        .{ .expected_type = Kind.letKeyword, .expected_literal = "let" },
        .{ .expected_type = Kind.ident, .expected_literal = "add" },
        .{ .expected_type = Kind.assign, .expected_literal = "=" },
        .{ .expected_type = Kind.fnKeyword, .expected_literal = "fn" },
        .{ .expected_type = Kind.leftParenthesis, .expected_literal = "(" },
        .{ .expected_type = Kind.ident, .expected_literal = "x" },
        .{ .expected_type = Kind.comma, .expected_literal = "," },
        .{ .expected_type = Kind.ident, .expected_literal = "y" },
        .{ .expected_type = Kind.rightParenthesis, .expected_literal = ")" },
        .{ .expected_type = Kind.leftBrace, .expected_literal = "{" },
        .{ .expected_type = Kind.ident, .expected_literal = "x" },
        .{ .expected_type = Kind.plus, .expected_literal = "+" },
        .{ .expected_type = Kind.ident, .expected_literal = "y" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.rightBrace, .expected_literal = "}" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },

        .{ .expected_type = Kind.letKeyword, .expected_literal = "let" },
        .{ .expected_type = Kind.ident, .expected_literal = "result" },
        .{ .expected_type = Kind.assign, .expected_literal = "=" },
        .{ .expected_type = Kind.ident, .expected_literal = "add" },
        .{ .expected_type = Kind.leftParenthesis, .expected_literal = "(" },
        .{ .expected_type = Kind.ident, .expected_literal = "five" },
        .{ .expected_type = Kind.comma, .expected_literal = "," },
        .{ .expected_type = Kind.ident, .expected_literal = "ten" },
        .{ .expected_type = Kind.rightParenthesis, .expected_literal = ")" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.eof, .expected_literal = "" },
    };

    var lexer = Lexer.new(input);

    inline for (tests) |tt| {
        const tok = lexer.nextToken();
        try testing.expectEqual(tt.expected_type, tok.kind);
        try testing.expectEqualStrings(tt.expected_literal, tok.span);
    }
}
