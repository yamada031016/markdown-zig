const TokenType = enum {
    Heading,
    List,
    Bold,
    Italic,
    Paragraph,
};

pub const Token = union(TokenType) {
    Heading: struct { level: usize, text: []const u8 },
    List: []const u8,
    Bold: []const u8,
    Italic: []const u8,
    Paragraph: []const u8,
};
