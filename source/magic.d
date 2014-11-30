module magic;

private import core.stdc.stddef; // for size_t
private import std.string;

extern (C) {
@system:
nothrow:

alias magic_t = void *;

magic_t magic_open(int flags);
void magic_close(magic_t ms);

immutable(char) *magic_getpath(in char *path, int flags);
immutable(char) *magic_file(magic_t ms, in char *path);
immutable(char) *magic_descriptor(magic_t ms, int fd);
immutable(char) *magic_buffer(magic_t ms, in void *buffer, size_t length);

immutable(char) *magic_error(magic_t ms);
int magic_setflags(magic_t ms, int flags);

int magic_version();
int magic_load(magic_t ms, in char *path);
int magic_compile(magic_t ms, in char *path);
int magic_check(magic_t ms, in char *path);
int magic_list(magic_t ms, in char *path);
int magic_errno(magic_t ms);


enum
	MAGIC_NONE              = 0x000000, /// No flags
	MAGIC_DEBUG             = 0x000001, /// Turn on debugging
	MAGIC_SYMLINK           = 0x000002, /// Follow symlinks
	MAGIC_COMPRESS          = 0x000004, /// Check inside compressed files
	MAGIC_DEVICES           = 0x000008, /// Look at the contents of devices
	MAGIC_MIME_TYPE         = 0x000010, /// Return the MIME type
	MAGIC_CONTINUE          = 0x000020, /// Return all matches
	MAGIC_CHECK             = 0x000040, /// Print warnings to stderr
	MAGIC_PRESERVE_ATIME    = 0x000080, /// Restore access time on exit
	MAGIC_RAW               = 0x000100, /// Don't translate unprintable chars
	MAGIC_ERROR             = 0x000200, /// Handle ENOENT etc as real errors
	MAGIC_MIME_ENCODING     = 0x000400, /// Return the MIME encoding
	MAGIC_APPLE             = 0x000800; /// Return the Apple creator and type


enum
	MAGIC_MIME              = MAGIC_MIME_TYPE | MAGIC_MIME_ENCODING;


enum
	MAGIC_NO_CHECK_COMPRESS = 0x001000, /// Don't check for compressed files
	MAGIC_NO_CHECK_TAR      = 0x002000, /// Don't check for tar files
	MAGIC_NO_CHECK_SOFT     = 0x004000, /// Don't check magic entries
	MAGIC_NO_CHECK_APPTYPE  = 0x008000, /// Don't check application type
	MAGIC_NO_CHECK_ELF      = 0x010000, /// Don't check for elf details
	MAGIC_NO_CHECK_TEXT     = 0x020000, /// Don't check for text files
	MAGIC_NO_CHECK_CDF      = 0x040000, /// Don't check for cdf files
	MAGIC_NO_CHECK_TOKENS   = 0x100000, /// Don't check tokens
	MAGIC_NO_CHECK_ENCODING = 0x200000; /// Don't check text encodings


/++ No built-in tests; only consult the magic file +/
enum
	MAGIC_NO_CHECK_BUILTIN  = MAGIC_NO_CHECK_COMPRESS
	                        | MAGIC_NO_CHECK_TAR
	                     // | MAGIC_NO_CHECK_SOFT
	                        | MAGIC_NO_CHECK_APPTYPE
	                        | MAGIC_NO_CHECK_ELF
	                        | MAGIC_NO_CHECK_TEXT
	                        | MAGIC_NO_CHECK_CDF
	                        | MAGIC_NO_CHECK_TOKENS
	                        | MAGIC_NO_CHECK_ENCODING;


/++ Defined for backwards compatibility (renamed) +/
enum
	MAGIC_NO_CHECK_ASCII    = MAGIC_NO_CHECK_TEXT;


/++ Defined for backwards compatibility; do nothing +/
enum
	MAGIC_NO_CHECK_FORTRAN  = MAGIC_NONE, /// Don't check ascii/fortran
	MAGIC_NO_CHECK_TROFF    = MAGIC_NONE; /// Don't check ascii/troff

enum
	MAGIC_VERSION = 516; /// This implementation
}

class MagicOpenFail: Error {
	@safe pure nothrow this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
	{
		super("Failed to create magic cookie", file, line, next);
	}
}

class Magic {
protected:
	magic_t m;

public:
	this(int flags = MAGIC_MIME_TYPE | MAGIC_NO_CHECK_BUILTIN) {
		m = magic_open(flags);

		if (!m)
			throw new MagicOpenFail();
	}

	~this() {
		magic_close(m);
	}

	bool setflags(int flags) {
		return magic_setflags(m, flags) == 0;
	}


	@property string error() {
		return fromStringz(magic_error(m));
	}

	@property int errno() {
		return magic_errno(m);
	}


	string file(in string path) {
		return fromStringz(magic_file(m, toStringz(path)));
	}

	string descriptor(int fd) {
		return fromStringz(magic_descriptor(m, fd));
	}

	string buffer(in void *buffer, size_t length) {
		return fromStringz(magic_buffer(m, buffer, length));
	}

	string buffer(T)(in T buffer[]) {
		return fromStringz(magic_buffer(m, buffer.ptr, buffer.sizeof));
	}


	bool load(in string path = null) {
		const char *p = path ? toStringz(path) : null;
		return magic_load(m, p) == 0;
	}

	bool compile(in string path = null) {
		const char *p = path ? toStringz(path) : null;
		return magic_compile(m, p) == 0;
	}

	bool check(in string path = null) {
		const char *p = path ? toStringz(path) : null;
		return magic_check(m, p) == 0;
	}

	bool list(in string path = null) {
		const char *p = path ? toStringz(path) : null;
		return magic_list(m, p) == 0;
	}
}

unittest {
	import std.path: getcwd, buildPath;
	import std.stdio: File;

	auto sample_dir = buildPath(getcwd(), "test_assets");
	auto sample_file = buildPath(getcwd(), "test_assets", "sample200.png");

	ubyte[] sample_rar = [
		0x52, 0x61, 0x72, 0x21, 0x1a, 0x07, 0x00, 0xcf,
		0x90, 0x73, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00,
	];

	auto f = new File(sample_file, "rb");

	auto m = new Magic();
	m.load();

	assert(m.file(sample_dir) == "inode/directory");
	assert(m.file(sample_file) == "image/png");
	assert(m.descriptor(f.fileno()) == "image/png");
	assert(m.buffer(sample_rar) == "application/x-rar");
}
