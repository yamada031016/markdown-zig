const std = @import("std");
const Token = @import("token.zig").Token;

pub fn htmlConverter(writer: anytype) HtmlConverter(@TypeOf(writer)) {
    return .{ .writer = writer };
}

fn HtmlConverter(comptime Writer: type) type {
    return struct {
        buf: [1024 * 10]u8 = undefined,
        idx: usize = 0,
        writer: Writer,

        const Self = @This();

        pub fn mdToHTML(self: *Self, ast: []const Token) !void {
            var tmp_buf: [4 * 1024]u8 = undefined;
            for (ast) |token| {
                const html = convert: {
                    switch (token) {
                        .Heading => |h| break :convert try std.fmt.bufPrint(&tmp_buf, "<h{}>{s}</h{}>", .{ h.level, h.text, h.level }),
                        .List => |l| break :convert try std.fmt.bufPrint(&tmp_buf, "<li>{s}</li>", .{l}),
                        .Bold => |b| break :convert try std.fmt.bufPrint(&tmp_buf, "<strong>{s}</strong>", .{b}),
                        .Italic => |i| break :convert try std.fmt.bufPrint(&tmp_buf, "<em>{s}</em>", .{i}),
                        .Paragraph => |p| break :convert try std.fmt.bufPrint(&tmp_buf, "<p>{s}</p>", .{p}),
                    }
                };
                if (self.buf.len < self.idx + html.len) {
                    try self.write();
                }
                @memcpy(self.buf[self.idx .. self.idx + html.len], html);
                self.idx += html.len;
            }

            try self.write();
        }

        pub fn write(self: *Self) !void {
            _ = try self.writer.write(self.buf[0..self.idx]);
            self.idx = 0;
        }
    };
}
