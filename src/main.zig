const std = @import("std");
const app = @import("game.zig");
const App = @import("game.zig").GameState;
const debug = std.debug;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os.linux;

/// Represent the size of the window to render into
// TODO is this in chars or in pixels
const Size = struct { width: usize, height: usize };

var i: usize = 0;
var size: Size = undefined;
var tty: fs.File = undefined;
var cooked_termios: os.termios = undefined; // represent the original state before raw mode
var raw: os.termios = undefined;

/// My app need to handle 5 input channels
/// writing/reading escape sequences, termios, ioctl, signals
/// SIGWINCH is used to signal window changed size
pub fn main() !void {
    // Get a file handler to this terminals tty
    tty = try fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write });
    defer tty.close();

    // Enter alternative screen and raw mode
    try uncook();
    defer cook() catch {};

    // Get the size of the current window to draw into
    size = try getSize();

    // Setup a handler to SIGWINCH to react to resize of window
    _ = os.sigaction(std.posix.SIG.WINCH, &os.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = os.empty_sigset,
        .flags = 0,
    }, null);

    var app_state = App.init(&i, &tty, &size.width, &size.height);

    while (!app_state.quit) {
        app_state.render();

        var buffer: [1]u8 = undefined;
        _ = try tty.read(&buffer); // this example driven by read, this blocks until next key press??

        app_state.handle_input(buffer[0]);
    }
}

/// Puts the termios object into raw mode and have the ability to customize how to do wait for input
fn cfmakeraw(tio: *os.termios, vtime: bool, vbyte: bool) void {
    tio.iflag.BRKINT = false;
    tio.iflag.PARMRK = false;
    tio.iflag.ISTRIP = false;
    tio.iflag.INLCR = false;
    tio.iflag.IGNCR = false;
    tio.iflag.IXON = false;

    tio.iflag.IGNBRK = false;

    tio.oflag.OPOST = false;
    tio.lflag.ECHO = false;
    tio.lflag.ECHONL = false;
    tio.lflag.ICANON = false;
    tio.lflag.ISIG = false;
    tio.lflag.IEXTEN = false;
    tio.cflag.PARENB = false;
    tio.cflag.CSIZE = .CS8;
    tio.cc[@intFromEnum(os.V.TIME)] = @intFromBool(vtime);
    tio.cc[@intFromEnum(os.V.MIN)] = @intFromBool(vbyte);
}

fn uncook() !void {
    const writer = tty.writer();

    // TODO fancy error handling by using switch and errno look into term lib how they do.
    _ = os.tcgetattr(tty.handle, &cooked_termios);
    raw = cooked_termios;

    cfmakeraw(&raw, false, true);

    // todo user posix.errno used on return here to make real errors in zig, switch on the errno, check term lib for the pattern
    // flush will clean upp anythin in the input buffer
    _ = os.tcsetattr(tty.handle, .FLUSH, &raw);

    try hideCursor(writer);
    try enterAlt(writer);
    try clear(writer);
}

fn cook() !void {
    const writer = tty.writer();
    try clear(writer);
    try leaveAlt(writer);
    try showCursor(writer);
    try attributeReset(writer);
    // Restore to original terminal settings
    // TODO fancy error handling by using switch and errno look into term lib how they do.
    _ = os.tcsetattr(tty.handle, .FLUSH, &cooked_termios);
}

fn clear(writer: anytype) !void {
    try writer.writeAll("\x1B[2J");
}

fn enterAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[s"); // Save cursor position.
    try writer.writeAll("\x1B[?47h"); // Save screen.
    try writer.writeAll("\x1B[?1049h"); // Enable alternative buffer.
}

fn leaveAlt(writer: anytype) !void {
    try writer.writeAll("\x1B[?1049l"); // Disable alternative buffer.
    try writer.writeAll("\x1B[?47l"); // Restore screen.
    try writer.writeAll("\x1B[u"); // Restore cursor position.
}

fn hideCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25l");
}

fn showCursor(writer: anytype) !void {
    try writer.writeAll("\x1B[?25h");
}

fn attributeReset(writer: anytype) !void {
    try writer.writeAll("\x1B[0m");
}

fn getSize() !Size {
    var win_size = mem.zeroes(os.winsize);
    const err = os.ioctl(tty.handle, os.T.IOCGWINSZ, @intFromPtr(&win_size));
    if (std.posix.errno(err) != .SUCCESS) {
        return std.posix.unexpectedErrno(@enumFromInt(err));
    }
    return Size{
        .height = win_size.ws_row,
        .width = win_size.ws_col,
    };
}

fn handleSigWinch(_: c_int) callconv(.C) void {
    size = getSize() catch return;
    // render() catch return; // TODO how the hell to do this when i move render.
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
