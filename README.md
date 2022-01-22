# Wordler

Elixir puzzle solver for Wordler at https://www.powerlanguage.co.uk/wordle/

Usage:

```
iex> puzzle = Wordler.Puzzle.new()
%Wordler.Puzzle{word_list: [], ...}

iex> length(puzzle.solution_list)
4594

iex> guess = Wordler.Puzzle.new_guess(puzzle)
"irate"

iex> results = [true, "r", false, false, false]
[true, "r", false, false, false]

iex> puzzle = Wordler.Puzzle.handle_guess(puzzle, guess, results)
%Wordler.Puzzle{word_list: [], ...}

iex> length(puzzle.solution_list)
95
```

## Installation

The package can be installed by adding `wordler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wordler, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/wordler>.

Docs can be found at Zhttps://hexdocs.pm/wordler.

