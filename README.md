# 𝑓❨𝓍❩𝑑𝑜𝑐

**f(x)doc** (pronounced "function doc") is a syntax to document your shell 
functions with inline comments, and a utility to access those docstrings
from the command line.

Typical shell comments begin with a `#` character; f(x)doc docstrings begin 
with `#:` (the _prefix_). The prefix is followed by whitespace, a single symbol
(the _type indicator_), more whitespace, and finally the docstring itself.

For example, the following function definition—

<img src="https://raw.githubusercontent.com/zgracem/fxdoc/master/function-definition.png" width="550" height="164">

—will result in the following output:

<img src="https://raw.githubusercontent.com/zgracem/fxdoc/master/output.png" width="550" height="135">

## Installation

1. Run `bash --version` and make sure it's 4.0 or newer.
2. Clone this repository somewhere.
3. Add `. ~/somewhere/fxdoc/_init.bash` to your `.bashrc`.

## Usage

1. `fxdoc --syntax` prints the f(x)doc syntax reference.

    <img src="https://raw.githubusercontent.com/zgracem/fxdoc/master/type-indicators.png" width="550" height="656">

2. Document your shell functions accordingly.

3. You can then access your docstrings from the CLI in a nice format.

## Say hello

[zgm&#x40;inescapable&#x2e;org](mailto:zgm%40inescapable%2eorg)
