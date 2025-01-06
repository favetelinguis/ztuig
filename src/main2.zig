const std = @import("std");
const debug = std.debug;

// const game_lib = @import("game.zig");
const GameState = @import("game.zig").GameState;

// const gameInit_t = @TypeOf(game_lib.gameInit);
// var gameInit: *gameInit_t = undefined;
// This represent the state in my tui
// const GameStatePtr = *anyopaque;

// do *const make so that also the return is a *, not sure how this works.
var gameInit: *const fn () GameState = undefined;
// var gameReload: *const fn (GameStatePtr) void = undefined;
// var gameTick: *const fn (GameStatePtr) void = undefined;
var gameDraw: *const fn (*GameState) void = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    loadGameDll() catch @panic("Failed to load game.so");
    var game_state = gameInit();

    var count: u32 = 1;

    while (true) {
        if (count % 5 == 0) { // reload every 5 seconds
            unloadGameDll() catch unreachable;
            recompileGameDll(allocator) catch {
                std.debug.print("Failed to recompile game.dll\n", .{});
            };
            loadGameDll() catch @panic("Failed to load game.dll");
            // gameReload(game_state);
        }
        // gameTick(game_state);
        gameDraw(&game_state);
        // debug.print("Hello world\n", .{});
        std.time.sleep(1_000_000_000);
        count += 1;
    }
}

var game_dyn_lib: ?std.DynLib = null;
fn loadGameDll() !void {
    if (game_dyn_lib != null) return error.AlreadyLoaded;
    var dyn_lib = std.DynLib.open("zig-out/lib/libgame.so") catch {
        return error.OpenFail;
    };
    // TODO should I not do defer dyn_lib.close()
    game_dyn_lib = dyn_lib;
    gameInit = dyn_lib.lookup(@TypeOf(gameInit), "gameInit") orelse return error.LookupFail;
    // gameReload = dyn_lib.lookup(@TypeOf(gameReload), "gameReload") orelse return error.LookupFail;
    // gameTick = dyn_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.LookupFail;
    gameDraw = dyn_lib.lookup(@TypeOf(gameDraw), "gameDraw") orelse return error.LookupFail;
    std.debug.print("Loaded libgame.so\n", .{});
}

fn unloadGameDll() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

fn recompileGameDll(allocator: std.mem.Allocator) !void {
    const process_args = [_][]const u8{
        "zig",
        "build",
        "-Dgame_only=true",
    };
    var build_process = std.process.Child.init(&process_args, allocator);
    try build_process.spawn();
    // wait() returns a tagged union. If the compilations fails that union
    // will be in the state .{ .Exited = 2 }
    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.RecompileFail;
        },
        else => return,
    }
}
