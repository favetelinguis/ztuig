const std = @import("std");

pub fn run() !void {
    // Did not get it to work with ztuig to bad
    // const process_args = [_][]const u8{ "PATH=/home/henke/repos/zigs/ztuig/zig-out/bin", "wezterm", "cli", "split-pane", "--top", "--", "ztuig" };

    const process_args = [_][]const u8{ "wezterm", "cli", "split-pane", "--top", "--", "hx" };
    const allocator = std.heap.page_allocator;

    var build_process = std.process.Child.init(&process_args, allocator);
    try build_process.spawn();
    // wait() returns a tagged union. If the compilations fails that union
    // will be in the state .{ .Exited = 2 }
    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.FailedExecutingCildProcess;
        },
        else => return,
    }
}
