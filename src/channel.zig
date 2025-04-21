const std = @import("std");
const Mutex = std.Thread.Mutex;
const Cond = std.Thread.Condition;

pub fn Channel(comptime T: type) type {
    return struct {
        const Self = @This();
        lock: Mutex = .{},
        cond_send: Cond = .{},
        cond_recv: Cond = .{},
        data: ?T = null,
        has_data: bool = false,

        pub fn init() Channel(T) {
            return .{};
        }

        pub fn send(self: *Self, value: T) void {
            self.lock.lock();
            defer self.lock.unlock();

            while (self.has_data) self.cond_send.wait(&self.lock);

            self.data = value;
            self.has_data = true;
            self.cond_recv.signal();
        }

        pub fn recv(self: *Self) T {
            self.lock.lock();
            defer self.lock.unlock();

            while (!self.has_data)
                self.cond_recv.wait(&self.lock);

            const val = self.data.?;
            self.data = null;
            self.has_data = false;
            self.cond_send.signal();
            return val;
        }
    };
}
