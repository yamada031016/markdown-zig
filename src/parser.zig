const ab = @import("abelha");
const std = @import("std");
const Token = @import("token.zig").Token;

const ParseResult = ab.ParseResult;
const MdResult = ParseResult(Token);

const MdError = error{
    InvalidHeadingLevel,
    UnknownFormat,
};

pub fn parse_markdown(input: []const u8) !ParseResult([]const Token) {
    return try ab.separated_list1(Token, ab.newline, ab.alt(Token, .{
        heading,
        list_item,
        bold_text,
        italic_text,
        paragraph,
    }))(input);
}

pub fn heading(input: []const u8) !MdResult {
    var result = try ab.many1(ab.char('#'))(input);
    const level = result.result.len;
    if (level > 6) {
        return MdError.InvalidHeadingLevel;
    }
    result = try ab.space1(result.rest);
    result = try ab.take_until("\n")(result.rest);

    return MdResult{ .rest = result.rest, .result = .{ .Heading = .{ .level = level, .text = result.result } } };
}

test "parse heading" {
    const target = "## Zig lang.\n";
    const result = try heading(target);
    try std.testing.expectEqual(2, result.result.Heading.level);
    try std.testing.expectEqualStrings("Zig lang.", result.result.Heading.text);
}

pub fn list_item(input: []const u8) !MdResult {
    var result = try ab.char('-')(input);
    result = try ab.space1(result.rest);
    result = try ab.take_until("\n")(result.rest);
    return MdResult{ .rest = result.rest, .result = .{ .List = result.result } };
}

test "parse list item" {
    const target = "- item1\n";
    const result = try list_item(target);
    try std.testing.expectEqualStrings("item1", result.result.List);
}

pub fn bold_text(input: []const u8) !MdResult {
    const result = try ab.delimited(ab.tag("**"), ab.take_until("**"), ab.tag("**"))(input);
    return MdResult{ .rest = result.rest, .result = Token{ .Bold = result.result } };
}

test "parse bold text" {
    const target = "**This is bold text**";
    const result = try bold_text(target);
    try std.testing.expectEqualStrings("This is bold text", result.result.Bold);
}

pub fn italic_text(input: []const u8) !MdResult {
    const result = try ab.delimited(ab.tag("*"), ab.take_until("*"), ab.tag("*"))(input);
    return MdResult{ .rest = result.rest, .result = Token{ .Italic = result.result } };
}

test "parse italic text" {
    const target = "*This is italic text*";
    const result = try italic_text(target);
    try std.testing.expectEqualStrings("This is italic text", result.result.Italic);
}

pub fn paragraph(input: []const u8) !MdResult {
    const result = try ab.take_until("\n")(input);
    return MdResult{ .rest = result.rest, .result = Token{ .Paragraph = result.result } };
}
