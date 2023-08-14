extern "c" fn read_line(prompt: [*c]const u8, [*c]u8, capacity: c_int) c_int;

pub const InputError = error{
    OutOfMemory,
    EndOfFile,
    Interrupt,
    UnknownError,
    WindowResized,
    RustylineNotInit,
};

pub fn NewRepel(comptime size: usize) type {
    return struct {
        var buffer: [size]u8 = undefined;

        pub fn readLine(prompt: []const u8) InputError![]const u8 {
            switch (read_line(@ptrCast([*c]const u8, prompt), buffer[0..], size)) {
                -1 => return InputError.OutOfMemory,
                -2 => return InputError.EndOfFile,
                -3 => return InputError.Interrupt,
                -4 => return InputError.WindowResized,
                -5 => return InputError.UnknownError,
                -6 => return InputError.RustylineNotInit,
                else => |len| {
                    return buffer[0..@intCast(usize, len)];
                },
            }
        }
    };
}
