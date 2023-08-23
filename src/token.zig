pub const Kind = enum {
    Illegal,
    Eof,

    Ident,
    Int,
    Float,
    String,

    Assign,
    Plus,
    Minus,
    Bang,
    Asterisk,
    Slash,

    Eq,
    NEq,
    LT,
    GT,
    LEq,
    GEq,

    Comma,
    Semicolon,

    Lparan,
    Rparan,
    Lbrace,
    Rbrace,

    Fn,
    Let,
    True,
    False,
    If,
    Else,
    Return,
};

pub const Token = struct {
    kind: Kind,
    literal: []const u8,
};
