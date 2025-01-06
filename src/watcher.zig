// this is very much a rippoff from
// https://github.com/freref/fzwatch
// me just want to learn instead of using deps
const std = @import("std");
const fs = std.fs;
const testing = std.testing;

pub const Event = enum { modified };
const Callback = fn (context: std.mem.Allocator, event: Event) void;

pub const Watcher = struct {
    allocator: std.mem.Allocator,
    inotify_fd: i32,
    paths: std.ArrayList([]const u8),
    offset: usize,
    callback: ?*const Callback,
    running: bool,

    pub fn init(allocator: std.mem.Allocator) !Watcher {
        // Open fd in no blocking mode
        const fd = try std.posix.inotify_init1(std.os.linux.IN.NONBLOCK);
        errdefer std.posix.close(fd);

        return Watcher{
            .allocator = allocator,
            .inotify_fd = @intCast(fd),
            .paths = std.ArrayList([]const u8).init(allocator),
            .offset = 1,
            .callback = null,
            .running = false,
        };
    }

    pub fn deinit(self: *Watcher) void {
        self.stop();
        self.paths.deinit();
        std.posix.close(self.inotify_fd);
    }

    pub fn addFile(self: *Watcher, path: []const u8) !void {
        _ = try std.posix.inotify_add_watch(
            self.inotify_fd,
            path,
            std.os.linux.IN.MODIFY,
        );

        try self.paths.append(path);
    }

    pub fn removeFile(self: *Watcher, path: []const u8) !void {
        for (0.., self.paths) |idx, mem_path| {
            if (mem_path == path) {
                _ = std.posix.inotify_rm_watch(self.inotify_fd, idx - self.offset);
                try self.paths.items().remove(idx);
                self.offset += 1;
                return;
            }
        }
    }

    pub fn setCallback(self: *Watcher, callback: Callback) void {
        self.callback = callback;
    }

    pub fn start(self: *Watcher) !void {
        if (self.paths.items.len == 0) return error.NoFilesToWatch;

        self.running = true;
        var buffer: [4096]u8 align(@alignOf(std.os.linux.inotify_event)) = undefined;

        while (self.running) {
            const length = std.posix.read(self.inotify_fd, &buffer) catch |err| switch (err) {
                error.WouldBlock => {
                    // think this will check every about 500ms if any changes has happened
                    std.time.sleep(std.time.ns_per_ms * 500);
                    continue;
                },
                else => {
                    return err;
                },
            };

            var ptr: [*]u8 = &buffer;
            const end_ptr = ptr + @as(usize, @intCast(length));

            // I dont understand this while for shit, copy paste from fzwatch
            while (@intFromPtr(ptr) < @intFromPtr(end_ptr)) {
                const ev = @as(*const std.os.linux.inotify_event, @ptrCast(@alignCast(ptr)));
                // Editors like vim create temporary files when saving
                // So we have to re-add the file to the watcher
                if (ev.mask & std.os.linux.IN.IGNORED != 0) {
                    const wd_usize = @as(usize, @intCast(@max(0, ev.wd)));
                    if (wd_usize < self.offset) {
                        return error.InvalidWatchDescriptor;
                    }
                    const index = wd_usize - self.offset;
                    try self.addFile(self.paths.items[index]);
                    if (self.callback) |callback| {
                        callback(self.allocator, Event.modified);
                    }
                } else if (ev.mask & std.os.linux.IN.MODIFY != 0) {
                    if (self.callback) |callback| {
                        callback(self.allocator, Event.modified);
                    }
                }

                ptr = @alignCast(ptr + @sizeOf(std.os.linux.inotify_event) + ev.len);
            }
        }
    }

    pub fn stop(self: *Watcher) void {
        self.running = false;
    }
};

test "init" {
    // try testing.expect(11 == 10);
}
