import std.stdio;
import magic;

int main(string[] args)
{
	if (args.length == 1) {
		writefln("Usage: %s [file1 [file2 [...]]]", args[0]);
		return 1;
	}

	auto m = new Magic(MAGIC_MIME_TYPE | MAGIC_NO_CHECK_BUILTIN);

	m.load(null);

	foreach (path; args[1..$])
		writefln("%s: %s", m.file(path), path);

	return 0;
}
