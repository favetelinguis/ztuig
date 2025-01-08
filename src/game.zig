const std = @import("std");
const wez = @import("wezterm.zig");
const fs = std.fs;

pub const GameState = struct {
    i: *usize = undefined,
    tty: *fs.File = undefined,
    width: *usize = undefined,
    height: *usize = undefined,
    quit: bool = false,
};

export fn gameInit(i: *usize, tty: *fs.File, width: *usize, height: *usize) *GameState {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var app = allocator.create(GameState) catch @panic("out of memory");
    app.i = i;
    app.tty = tty;
    app.width = width;
    app.height = height;

    return app;
}

export fn gameRender(self: *GameState) void {
    const writer = self.tty.writer();
    writeLine(writer, "foo", 0, self.width.*, self.i.* == 0);
    writeLine(writer, "bar", 1, self.width.*, self.i.* == 1);
    writeLine(writer, "baz", 2, self.width.*, self.i.* == 2);
    writeLine(writer, "xyzzy", 3, self.width.*, self.i.* == 3);
}

// TODO i dont support esc sequences add support for kitty keyboard protocol
// add query terminal if they support that if not panic, no point trying to do this other way
export fn gameHandleInput(self: *GameState, buffer: u8) void {
    switch (buffer) {
        'q' => self.quit = true,
        's' => wez.run() catch @panic("Failure running chile process"),
        'j' => self.i.* = @min(self.i.* + 1, 3),
        'k' => self.i.* -|= 1,

        // '\x1b' => { // handle esc like alt key, we want to check if ther are more bytes in buffer
        //     // dont block waiting for bytes but return right away, we just want to know if there is more in the buffer
        //     cfmakeraw(&raw, true, false);
        //     // .now so we dont flush what is left in the buffer
        //     _ = os.tcsetattr(tty.handle, .NOW, &raw);

        //     // try to read remaining bytes, i guess 8 bytes is the maximum long an esc sequence can be
        //     var esc_buffer: [8]u8 = undefined;
        //     const esc_read = try tty.read(&esc_buffer);

        //     // restore we once again block until new bytes arrive in the input
        //     cfmakeraw(&raw, false, true);
        //     _ = os.tcsetattr(tty.handle, .NOW, &raw);

        //     if (mem.eql(u8, esc_buffer[0..esc_read], "[A")) {
        //         i -|= 1;
        //     } else if (mem.eql(u8, esc_buffer[0..esc_read], "[B")) {
        //         i = @min(i + 1, 3);
        //     }
        // },
        // '\n', '\r' => std.log.debug("input: return\r\n", .{}),
        else => unreachable, //std.log.debug("input: {} {s}\r\n", .{ buffer[0], buffer }),
    }
}

/// Do any update logic that need to be done after each hot reload
export fn gameReload(self: *GameState) void {
    _ = self;
}

fn writeLine(writer: anytype, txt: []const u8, y: usize, width: usize, selected: bool) void {
    if (selected) {
        blueBackground(writer);
    } else {
        attributeReset(writer);
    }
    moveCursor(writer, y, 0);
    writer.writeAll(txt) catch @panic("Failure writing");
    writer.writeByteNTimes(' ', width - txt.len) catch @panic("Failure writing");
}

fn blueBackground(writer: anytype) void {
    writer.writeAll("\x1B[44m") catch @panic("Failure writing blue background");
}

fn attributeReset(writer: anytype) void {
    writer.writeAll("\x1B[0m") catch @panic("Failure writing");
}

/// Use zero based movement of cursor
fn moveCursor(writer: anytype, row: usize, col: usize) void {
    // CSI for cursor position CUP
    _ = writer.print("\x1B[{};{}H", .{ row + 1, col + 1 }) catch @panic("Failure writing");
}
