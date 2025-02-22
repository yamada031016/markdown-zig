const TokenType = enum {
    Heading,
    List,
    Bold,
    Italic,
    InlineCode,
    CodeBlock,
    BlockQuote,
    Paragraph,
};

pub const Token = union(TokenType) {
    Heading: struct { level: usize, text: []const u8 },
    List: []const u8,
    Bold: []const u8,
    Italic: []const u8,
    InlineCode: []const u8,
    CodeBlock: []const u8,
    BlockQuote: []const u8,
    Paragraph: []const u8,
};

const NodeType = enum { Block, Inline };
pub const Node = union(NodeType) {
    Block: BlockElement,
    Inline: InlineElement,
};

const BlockType = enum {
    Paragraph,
    Heading,
    BlockQuote,
    CodeBlock,
    List,
    Table,
    HorizontalRule,
    RawHtml,
};
pub const BlockElement = union(BlockType) {
    Paragraph: []const InlineElement,
    Heading: struct { level: u8, content: []const InlineElement },
    BlockQuote: []const BlockElement,
    CodeBlock: struct { lang: ?[]const u8 = null, code: []const u8 },
    List: struct { items: []const ListItem, ordered: bool },
    Table: struct { headers: [][]const u8, rows: [][][]const u8 },
    HorizontalRule,
    RawHtml: []const u8,
};

pub const ListItem = struct {
    content: []const InlineElement,
    checked: bool,
};

const InlineType = enum {
    Text,
    Emphasis,
    Strong,
    Strikethrough,
    InlineCode,
    Link,
    Image,
};
pub const InlineElement = union(InlineType) {
    Text: []const u8,
    Emphasis: []const InlineElement,
    Strong: []const InlineElement,
    Strikethrough: []const InlineElement,
    InlineCode: []const u8,
    Link: struct { text: []const u8, url: []const u8 },
    Image: struct { alt: []const u8, src: []const u8 },
};
