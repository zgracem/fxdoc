# 𝑓(𝓍)𝑑𝑜𝑐

**f(x)doc** (pronounced "function doc") is a syntax to document your shell 
functions with inline comments, and a utility to access those docstrings
from the command line.

Typical shell comments begin with a `#` character; f(x)doc docstrings begin 
with `#:` (the _prefix_). The prefix is followed by whitespace, a single symbol
(the _type indicator_), more whitespace, and finally the docstring itself.

For example, the following function definition—

```bash
daysold()
{ #: - finds files that have been modified in the last N days
  #: $ daysold <n> [dir]
  #: | n   = maximum age of found files, in days
  #: | dir = directory to search (default: PWD)

  mdfind -onlyin "${2-.}" "kMDItemFSContentChangeDate>\$time.today(-$1)"
}
```

—will result in the following output:

```
$ fxdoc daysold
daysold – finds files that have been modified in the last N days
Usage: daysold <n> [dir]
Options:
  n   = maximum age of found files
  dir = directory to search (default: PWD)
```

## Installation

1. Run `bash --version` and make sure it's 4.0 or newer.
2. Clone this repository somewhere.
3. Add `. ~/somewhere/fxdoc/_init.bash` to your `.bashrc`.

## Usage

1. `fxdoc --syntax` prints the f(x)doc syntax reference.

    <img src="https://raw.githubusercontent.com/zgracem/fxdoc/master/type-indicators.png" width="550" height="180">

2. Document your shell functions accordingly.

3. You can then access your docstrings from the CLI in a nice format.

## Examples

Most of the shell functions in my [dotfiles][] are documented with f(x)doc.
Check the `bash/functions.d` and `sh/profile.d` directories.

[dotfiles]: https://github.com/zgracem/dotconfig

## Say hello

[zgm&#x40;inescapable&#x2e;org](mailto:zgm%40inescapable%2eorg)
