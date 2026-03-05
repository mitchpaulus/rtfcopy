This is a repository of an extremely simple CLI utility for Windows.

This CLI should take RTF text, assumed to be ASCII, and put it on the Windows clipboard.
This tool should be built with Zig, compiled to a single file binary.

The usage should look like:

```
printf '{\rtf1...}' | rtfcopy
rtfcopy myfile.rtf
```
