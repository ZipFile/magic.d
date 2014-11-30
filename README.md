# magic.d

D binding around [magic number recognition library](http://www.darwinsys.com/file/ "libmagic").

See `man 3 libmagic` for more info.

## Usage
``` d
import magic;

auto m = new Magic(MAGIC_MIME_TYPE | MAGIC_NO_CHECK_BUILTIN);

m.load(null);

ubyte[] rar = [
	0x52, 0x61, 0x72, 0x21, 0x1a, 0x07, 0x00, 0xcf,
	0x90, 0x73, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00,
];

assert(m.buffer(rar) == "application/x-rar");
```
