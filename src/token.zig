pub const Kind = enum {
    illegal,
    eof,

    ident,
    intLiteral,

    assign,
    plus,

    comma,
    semicolon,

    leftParenthesis,
    rightParenthesis,
    leftBrace,
    rightBrace,

    fnKeyword,
    letKeyword,
};

/// Token
///
/// fields:
/// kind is enum which identifies what kind of token is it
/// span is the part of actual source code
pub const Token = struct {
    kind: Kind,
    span: []const u8,
};
