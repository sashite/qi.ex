# qi.ex

[![Hex Version](https://img.shields.io/hexpm/v/qi.svg)](https://hex.pm/packages/qi)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/qi/)
[![CI](https://github.com/sashite/qi.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/sashite/qi.ex/actions)
[![License](https://img.shields.io/hexpm/l/qi.svg)](https://github.com/sashite/qi.ex/blob/main/LICENSE)

> A minimal, format-agnostic position model for two-player board games.

## Overview

`Qi` provides an immutable `Qi.Position` struct that represents the state of a two-player, turn-based board game as defined by the [Sashité Game Protocol](https://sashite.dev/game-protocol/).

A position encodes exactly four things:

| Field    | Type                              | Description                                        |
|----------|-----------------------------------|----------------------------------------------------|
| `board`  | nested list (1D to 3D)            | Board structure and occupancy                      |
| `hands`  | `%{first: list, second: list}`    | Off-board pieces held by each player               |
| `styles` | `%{first: term, second: term}`    | Player style for each side                         |
| `turn`   | `:first` or `:second`             | The active player's side                           |

Piece and style representations are **intentionally opaque** — `Qi` validates structure, not semantics. This makes the library reusable across [FEEN](https://sashite.dev/specs/feen/1.0.0/), [PON](https://sashite.dev/specs/pon/1.0.0/), or any other encoding that shares the same positional model.

### Implementation Constraints

| Constraint         | Value | Rationale                                 |
|--------------------|-------|-------------------------------------------|
| Max dimensions     | 3     | Covers 1D, 2D, 3D boards                 |
| Max dimension size | 255   | Fits in 8-bit integer; covers 255×255×255 |
| Board non-empty    | n ≥ 1 | A board must contain at least one square  |
| Piece cardinality  | p ≤ n | Pieces cannot exceed the number of squares|

## Installation

```elixir
# In your mix.exs
def deps do
  [
    {:qi, "~> 1.0"}
  ]
end
```

## Dependencies

None. `Qi` is a zero-dependency library.

## Usage

### Creating a Position

```elixir
# Chess starting position
board = [
  [:r, :n, :b, :q, :k, :b, :n, :r],
  [:p, :p, :p, :p, :p, :p, :p, :p],
  [nil, nil, nil, nil, nil, nil, nil, nil],
  [nil, nil, nil, nil, nil, nil, nil, nil],
  [nil, nil, nil, nil, nil, nil, nil, nil],
  [nil, nil, nil, nil, nil, nil, nil, nil],
  [:P, :P, :P, :P, :P, :P, :P, :P],
  [:R, :N, :B, :Q, :K, :B, :N, :R]
]

{:ok, position} = Qi.new(
  board,
  %{first: [], second: []},
  %{first: "C", second: "c"},
  :first
)
```

### Accessing Fields

```elixir
position.board   #=> [[:r, :n, :b, ...], ...]
position.hands   #=> %{first: [], second: []}
position.styles  #=> %{first: "C", second: "c"}
position.turn    #=> :first
```

### Bang Variant

```elixir
# Raises ArgumentError on invalid input
position = Qi.new!(board, hands, styles, :first)
```

### Tagged Tuple Variant

```elixir
# Returns {:ok, position} or {:error, %ArgumentError{}}
case Qi.new(board, hands, styles, :first) do
  {:ok, position} -> position
  {:error, error} -> handle_error(error)
end
```

### Pieces as Arbitrary Terms

Pieces are not restricted to any specific format. You can use atoms, strings (EPIN tokens), tuples, or any non-nil Elixir term:

```elixir
# Atoms
Qi.new!([:k, :p, nil, :P, :K], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

# EPIN strings
Qi.new!([["K^", nil], [nil, "k^"]], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

# Tuples
Qi.new!(
  [[{:king, :first, true}, nil], [nil, {:king, :second, true}]],
  %{first: [], second: []},
  %{first: :chess, second: :chess},
  :first
)
```

### Multi-dimensional Boards

```elixir
# 1D board
Qi.new!([:a, nil, :b], %{first: [], second: []}, %{first: "G", second: "g"}, :first)

# 2D board (standard)
Qi.new!([[nil, nil], [nil, nil]], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

# 3D board (2 layers × 2 ranks × 2 files)
board_3d = [
  [[:a, :b], [:c, :d]],
  [[:A, :B], [:C, :D]]
]
Qi.new!(board_3d, %{first: [], second: []}, %{first: "R", second: "r"}, :first)
```

### Hands with Captured Pieces

```elixir
# Shogi-like position with pieces in hand
Qi.new!(
  [[nil, nil, nil], [nil, "K^", nil], [nil, nil, nil]],
  %{first: ["P", "P", "B"], second: ["p"]},
  %{first: "S", second: "s"},
  :first
)
```

## Validation Errors

| Error message                          | Cause                                    |
|----------------------------------------|------------------------------------------|
| `"board must be a list"`               | Board is not a list                      |
| `"board must not be empty"`            | Board is `[]`                            |
| `"board exceeds 3 dimensions (got N)"` | More than 3 nesting levels              |
| `"dimension size N exceeds maximum of 255"` | A dimension has more than 255 elements |
| `"non-rectangular board: ..."`         | Sub-arrays at the same level differ in length |
| `"inconsistent board structure: mixed lists and non-lists at same level"` | Mixed lists and non-lists at the same nesting level |
| `"inconsistent board structure: expected flat squares at this level"` | A list found where a leaf square was expected |
| `"hands must be a map with keys :first and :second"` | Hands is not a map |
| `"hands must have exactly keys :first and :second"` | Map has missing or extra keys |
| `"each hand must be a list"`           | Hand value is not a list                 |
| `"hand pieces must not be nil"`        | `nil` found in a hand list               |
| `"styles must be a map with keys :first and :second"` | Styles is not a map |
| `"styles must have exactly keys :first and :second"` | Map has missing or extra keys |
| `"first player style must not be nil"` | First style value is `nil`               |
| `"second player style must not be nil"` | Second style value is `nil`             |
| `"turn must be :first or :second"`     | Invalid turn value                       |
| `"too many pieces for board size (P pieces, N squares)"` | Piece cardinality violation |

## Design Principles

- **Format-agnostic**: No dependency on EPIN, SIN, or any specific encoding.
- **Protocol-aligned**: Structurally compatible with the Game Protocol's Position model.
- **Purely functional**: No mutable state, no side effects, no processes.
- **Validated at construction**: All invariants are enforced when building a position.
- **Zero dependencies**: Only the Elixir standard library.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [PON Specification](https://sashite.dev/specs/pon/1.0.0/) — JSON-based position format
- [FEEN Specification](https://sashite.dev/specs/feen/1.0.0/) — Canonical string-based position format
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Piece token format
- [SIN Specification](https://sashite.dev/specs/sin/1.0.0/) — Style token format

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
