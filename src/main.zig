const std = @import("std");
const windows = std.os.windows;

const HANDLE = windows.HANDLE;
const HGLOBAL = ?*anyopaque;
const UINT = c_uint;
const BOOL = windows.BOOL;

const GMEM_MOVEABLE = 0x0002;
const CF_TEXT = 1;

extern "kernel32" fn GlobalAlloc(uFlags: UINT, dwBytes: usize) callconv(.winapi) HGLOBAL;
extern "kernel32" fn GlobalLock(hMem: HGLOBAL) callconv(.winapi) ?[*]u8;
extern "kernel32" fn GlobalUnlock(hMem: HGLOBAL) callconv(.winapi) BOOL;

extern "user32" fn OpenClipboard(hWndNewOwner: ?HANDLE) callconv(.winapi) BOOL;
extern "user32" fn CloseClipboard() callconv(.winapi) BOOL;
extern "user32" fn EmptyClipboard() callconv(.winapi) BOOL;
extern "user32" fn SetClipboardData(uFormat: UINT, hMem: HANDLE) callconv(.winapi) ?HANDLE;
extern "user32" fn RegisterClipboardFormatA(lpszFormat: [*:0]const u8) callconv(.winapi) UINT;

fn die(comptime msg: []const u8) noreturn {
    std.debug.print("rtfcopy: {s}\n", .{msg});
    std.process.exit(1);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Get RTF data: from file arg or stdin
    const data = blk: {
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        if (args.len > 1 and (std.mem.eql(u8, args[1], "-h") or std.mem.eql(u8, args[1], "--help"))) {
            std.debug.print("Usage: rtfcopy [file]\n\nCopies RTF text to the Windows clipboard.\nReads from file argument or stdin.\n", .{});
            std.process.exit(0);
        }

        if (args.len > 1) {
            const file = std.fs.cwd().openFile(args[1], .{}) catch
                die("cannot open file");
            defer file.close();
            break :blk file.readToEndAlloc(allocator, 64 * 1024 * 1024) catch
                die("cannot read file");
        } else {
            break :blk std.fs.File.stdin().readToEndAlloc(allocator, 64 * 1024 * 1024) catch
                die("cannot read stdin");
        }
    };
    defer allocator.free(data);

    if (data.len == 0) die("no input");

    // Register RTF clipboard format
    const cf_rtf = RegisterClipboardFormatA("Rich Text Format");
    if (cf_rtf == 0) die("cannot register RTF format");

    // Open clipboard
    if (OpenClipboard(null) == 0) die("cannot open clipboard");
    defer _ = CloseClipboard();

    if (EmptyClipboard() == 0) die("cannot empty clipboard");

    // Set RTF data
    setClipboardFormat(cf_rtf, data) catch die("cannot set RTF clipboard data");

    // Also set plain text as fallback
    setClipboardFormat(CF_TEXT, data) catch {};
}

fn setClipboardFormat(format: UINT, data: []const u8) !void {
    const hmem = GlobalAlloc(GMEM_MOVEABLE, data.len + 1) orelse return error.AllocFailed;
    const ptr = GlobalLock(hmem) orelse return error.LockFailed;
    @memcpy(ptr[0..data.len], data);
    ptr[data.len] = 0;
    _ = GlobalUnlock(hmem);

    if (SetClipboardData(format, @ptrCast(hmem)) == null) return error.SetFailed;
}
