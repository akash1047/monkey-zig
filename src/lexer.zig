const token = @import("./token.zig");
const Token = token.Token;
const Kind = token.Kind;

const std = @import("std");
const testing = std.testing;

const keywords = [_]struct {
    literal: []const u8,
    kind: Kind,
}{
    .{ .literal = "fn", .kind = .fnKeyword },
    .{ .literal = "let", .kind = .letKeyword },
    .{ .literal = "true", .kind = .trueKeyword },
    .{ .literal = "false", .kind = .falseKeyword },
    .{ .literal = "if", .kind = .ifKeyword },
    .{ .literal = "else", .kind = .elseKeyword },
    .{ .literal = "return", .kind = .returnKeyword },
};

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
            '=' => {
                if (self.peakChar() == '=') {
                    tok = token.wordToken(Kind.equal, self.source[self.position..], 2);
                    self.readChar();
                } else {
                    tok = token.charToken(Kind.assign, self.source[self.position..]);
                }
            },
            '!' => {
                if (self.peakChar() == '=') {
                    tok = token.wordToken(Kind.notEqual, self.source[self.position..], 2);
                    self.readChar();
                } else {
                    tok = token.charToken(Kind.bang, self.source[self.position..]);
                }
            },
            ';' => tok = token.charToken(Kind.semicolon, self.source[self.position..]),
            '(' => tok = token.charToken(Kind.leftParenthesis, self.source[self.position..]),
            ')' => tok = token.charToken(Kind.rightParenthesis, self.source[self.position..]),
            ',' => tok = token.charToken(Kind.comma, self.source[self.position..]),
            '+' => tok = token.charToken(Kind.plus, self.source[self.position..]),
            '{' => tok = token.charToken(Kind.leftBrace, self.source[self.position..]),
            '}' => tok = token.charToken(Kind.rightBrace, self.source[self.position..]),
            '-' => tok = token.charToken(Kind.minus, self.source[self.position..]),
            '/' => tok = token.charToken(Kind.slash, self.source[self.position..]),
            '*' => tok = token.charToken(Kind.asterisk, self.source[self.position..]),
            '<' => tok = token.charToken(Kind.lessThan, self.source[self.position..]),
            '>' => tok = token.charToken(Kind.greaterThan, self.source[self.position..]),
            0 => tok = .{ .kind = Kind.eof, .span = self.source[self.position..self.position] },
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
        if (self.read_position < self.source.len) {
            self.position = self.read_position;
            self.ch = self.source[self.read_position];
        } else {
            self.position = self.source.len;
            self.ch = 0;
        }

        self.read_position += 1;
    }

    fn peakChar(self: *Lexer) u8 {
        return if (self.read_position < self.source.len) self.source[self.read_position] else 0;
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
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if (5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
        \\10 != 9;
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

        .{ .expected_type = Kind.bang, .expected_literal = "!" },
        .{ .expected_type = Kind.minus, .expected_literal = "-" },
        .{ .expected_type = Kind.slash, .expected_literal = "/" },
        .{ .expected_type = Kind.asterisk, .expected_literal = "*" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "5" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },

        .{ .expected_type = Kind.intLiteral, .expected_literal = "5" },
        .{ .expected_type = Kind.lessThan, .expected_literal = "<" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.greaterThan, .expected_literal = ">" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "5" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },

        .{ .expected_type = Kind.ifKeyword, .expected_literal = "if" },
        .{ .expected_type = Kind.leftParenthesis, .expected_literal = "(" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "5" },
        .{ .expected_type = Kind.lessThan, .expected_literal = "<" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.rightParenthesis, .expected_literal = ")" },
        .{ .expected_type = Kind.leftBrace, .expected_literal = "{" },
        .{ .expected_type = Kind.returnKeyword, .expected_literal = "return" },
        .{ .expected_type = Kind.trueKeyword, .expected_literal = "true" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.rightBrace, .expected_literal = "}" },
        .{ .expected_type = Kind.elseKeyword, .expected_literal = "else" },
        .{ .expected_type = Kind.leftBrace, .expected_literal = "{" },
        .{ .expected_type = Kind.returnKeyword, .expected_literal = "return" },
        .{ .expected_type = Kind.falseKeyword, .expected_literal = "false" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.rightBrace, .expected_literal = "}" },

        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.equal, .expected_literal = "==" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.semicolon, .expected_literal = ";" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "10" },
        .{ .expected_type = Kind.notEqual, .expected_literal = "!=" },
        .{ .expected_type = Kind.intLiteral, .expected_literal = "9" },
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
