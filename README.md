# rtfcopy

Copies RTF text to the Windows clipboard so it can be properly pasted into applications that support rich text.

## Usage

```
rtfcopy myfile.rtf
echo '{\rtf1 Hello \b world\b0}' | rtfcopy
```

## Building

Requires [Zig](https://ziglang.org/) 0.15.x.

```
zig build -Dtarget=x86_64-windows -Drelease
```

The executable will be at `zig-out/bin/rtfcopy.exe`.
