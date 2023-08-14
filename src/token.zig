pub const Kind = enum {
    illegal,
    eof,

    ident,
    intLiteral,
    floatLiteral,

    assign,
    plus,
    minus,
    bang,
    asterisk,
    slash,

    equal,
    notEqual,
    lessThan,
    greaterThan,

    comma,
    semicolon,

    leftParenthesis,
    rightParenthesis,
    leftBrace,
    rightBrace,

    fnKeyword,
    letKeyword,
    trueKeyword,
    falseKeyword,
    ifKeyword,
    elseKeyword,
    returnKeyword,
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

pub fn charToken(k: Kind, s: []const u8) Token {
    return .{
        .kind = k,
        .span = s[0..1],
    };
}

pub fn wordToken(k: Kind, s: []const u8, len: usize) Token {
    return .{
        .kind = k,
        .span = s[0..len],
    };
}
