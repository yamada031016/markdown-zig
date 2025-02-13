const std = @import("std");
const md = @import("parser.zig");
const Token = @import("token.zig").Token;
const html = @import("html.zig");

pub fn main() !void {
    const text =
        \\# Title
        \\## Subtitle
        \\### Section
        \\- Item 1
        \\- Item 2
        \\**bold**
        \\*italic*
        \\Normal text
    ;
    const result = try md.parse_markdown(text);

    const writer = std.io.getStdOut().writer();
    // or
    // const html = try std.fs.cwd().createFile("md.html", .{});
    // const writer = html.writer();

    var hc = html.converter(writer);
    try hc.mdToHTML(result.result);
}
