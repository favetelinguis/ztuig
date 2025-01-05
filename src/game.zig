const std = @import("std");

pub const GameState = struct {};

pub export fn gameInit() *GameState {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    return allocator.create(GameState) catch @panic("out of memory");
}

pub export fn gameReload(game_state_ptr: *GameState) void {
    _ = game_state_ptr;
}

pub export fn gameTick(game_state_ptr: *GameState) void {
    _ = game_state_ptr;
}

pub export fn gameDraw(game_state_ptr: *GameState) void {
    _ = game_state_ptr;
}
