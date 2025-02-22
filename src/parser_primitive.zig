const ab = @import("abelha");
const std = @import("std");

const IResult = ab.IResult;

const separated_list1 = ab.structure.separated_list1;
const many1 = ab.combinator.many1;
const alt = ab.combinator.alt;
const tag = ab.basic.tag;
const take_until = ab.basic.take_until;
const delimited = ab.structure.delimited;
const many_till = ab.combinator.many_till;
const peek = ab.combinator.peek;

const MdError = error{
    InvalidHeadingLevel,
    UnknownFormat,
};

pub fn parse_markdown(input: []const u8) !ab.ParseResult([]const []const u8) {
    return try separated_list1([]const u8, ab.whitespace.newline, alt([]const u8, .{
        heading,
        list_item,
        paragraph,
    }))(input);
}

pub fn heading(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    defer array.deinit();
    const writer = array.writer();

    const result = try many1(tag("#"))(input);
    const level = result.result.len;
    if (level > 6) {
        return MdError.InvalidHeadingLevel;
    }
    const _result = try ab.structure.preceded(ab.whitespace.space1, take_until("\n"))(result.rest);

    try writer.print("<h{}>{s}</h{}>", .{ level, _result.result, level });

    return IResult{ .rest = _result.rest, .result = try array.toOwnedSlice() };
}

test "parse heading" {
    const target = "### Heading3\n";
    const result = try heading(target);
    try std.testing.expectEqualStrings("<h3>Heading3</h3>", result.result);
}

pub fn list_item(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    const writer = array.writer();

    const result = try ab.combinator.many_till(
        ab.structure.preceded(
            ab.combinator.opt(tag("\n")),
            ab.structure.preceded(tag("- "), take_until("\n")),
        ),
        alt([]const u8, .{
            peek(ab.combinator.not(tag("\n- "))),
            peek(tag("\n\n")),
            ab.combinator.eof,
        }),
    )(input);
    // const result = try separated_list1(
    //     []const u8,
    //     ab.whitespace.newline,
    //     ab.structure.preceded(
    //         tag("- "),
    //         take_until("\n"),
    //     ),
    // )(input);

    try writer.writeAll("<ul>");
    for (result.result) |list| {
        try writer.print("<li>{s}</li>", .{list});
    }
    try writer.writeAll("</ul>");
    return IResult{ .rest = result.rest, .result = try array.toOwnedSlice() };
}

test "parse list item" {
    const target = "- item1\n- item2\n";
    const result = try list_item(target);
    try std.testing.expectEqualStrings("<ul><li>item1</li><li>item2</li></ul>", result.result);
}

pub fn bold_text(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    const writer = array.writer();

    const result = try delimited(tag("**"), take_until("**"), tag("**"))(input);

    try writer.print("<strong>{s}</strong>", .{result.result});

    return IResult{ .rest = result.rest, .result = try array.toOwnedSlice() };
}

test "parse bold text" {
    const target = "**This is bold text**";
    const result = try bold_text(target);
    try std.testing.expectEqualStrings("<strong>This is bold text</strong>", result.result);
}

pub fn italic_text(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    const writer = array.writer();

    const result = try delimited(tag("*"), take_until("*"), tag("*"))(input);

    try writer.print("<em>{s}</em>", .{result.result});
    return IResult{ .rest = result.rest, .result = try array.toOwnedSlice() };
}

test "parse italic text" {
    const target = "*This is italic text*";
    const result = try italic_text(target);
    try std.testing.expectEqualStrings("<em>This is italic text</em>", result.result);
}

pub fn inline_code(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    const writer = array.writer();

    const result = try delimited(tag("`"), take_until("`"), tag("`"))(input);

    try writer.print("<code>{s}</code>", .{result.result});
    return IResult{ .rest = result.rest, .result = try array.toOwnedSlice() };
}

test "parse inline code" {
    const target = "`zig`";
    const result = try inline_code(target);
    try std.testing.expectEqualStrings("<code>zig</code>", result.result);
}

pub fn inlineElement(input: []const u8) !IResult {
    const result = try alt(
        []const u8,
        .{
            bold_text,
            italic_text,
            inline_code,
            ab.whitespace.newline,
            ab.basic.is_not("`[*"),
        },
    )(input);

    return IResult{ .rest = result.rest, .result = result.result };
}

pub fn paragraph(input: []const u8) !IResult {
    var array = std.ArrayList(u8).init(std.heap.page_allocator);
    const writer = array.writer();

    const recognize_end = alt([]const u8, .{ ab.whitespace.line_ending, ab.combinator.eof });
    const result = try ab.combinator.many_till(inlineElement, peek(recognize_end))(input);

    try writer.print("<p>{s}</p>", .{try std.mem.concat(std.heap.page_allocator, u8, result.result)});

    return IResult{ .rest = result.rest, .result = try array.toOwnedSlice() };
}

test "paragraph with inline elements" {
    const target = "`markdown-zig` is *markdown parser* using **abelha**\n";
    const result = try paragraph(target);
    try std.testing.expectEqualStrings("<p><code>markdown-zig</code> is <em>markdown parser</em> using <strong>abelha</strong></p>", result.result);
}

test "parse markdown" {
    const target =
        \\# Title
        \\## Subtitle
        \\### Section
        \\- Item 1
        \\- Item 2
        \\**bold**
        \\*italic*
        \\Normal text
    ;
    const result = try parse_markdown(target);
    try std.testing.expectEqualStrings(
        "<h1>Title</h1><h2>Subtitle</h2><h3>Section</h3><ul><li>Item 1</li><li>Item 2</li></ul><p><strong>bold</strong></p><p><em>italic</em></p><p>Normal text</p>",
        try std.mem.concat(std.heap.page_allocator, u8, result.result),
    );
}

// pub fn code_block(input: []const u8) {
//     const result = try delimited(tag("```"), take_until("```"), tag("```"))(input);
//     return IResult{ .rest = result.rest, .result = Token{ .CodeBlock = result.result } };
// }
//
// test "parse code block" {
//     const target = "*This is italic text*";
//     const result = try inline_code(target);
//     try std.testing.expectEqualStrings("This is italic text", result.result.Italic);
// }
//
// pub fn hyperlink(input: []const u8) !NodeResult {
//     const text = try delimited(tag("["), take_until("]"), tag("]"))(input);
//     _ = tag("(")(text.rest);
//     const url = try delimited(tag(""), take_until(")"), tag(")"))(input);
//     return NodeResult{
//         .rest = url.rest,
//         .result = token.Node{
//             .Inline = .{
//                 .Link = .{ .text = text.result, .url = url.result },
//             },
//         },
//     };
// }
//
// // pub fn block_quote(input: []const u8) !NodeResult {
// //     var result = try tag("> ")(input);
// //     result = try take_until("\n")(result.rest);
// // }
