# qi.ex

[![Hex Version](https://img.shields.io/hexpm/v/qi.svg)](https://hex.pm/packages/qi)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/qi)
[![CI](https://github.com/sashite/qi.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/sashite/qi.ex/actions)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://github.com/sashite/qi.ex/blob/main/LICENSE)

> An immutable, format-agnostic position model for two-player board games.

## Quick Start

```elixir
# Create an empty 8×8 board — "C" and "c" are style identifiers
# (here: Chess uppercase vs Chess lowercase)
pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")

# Place some pieces using flat indices (row-major order)
pos2 =
  pos
  |> Qi.board_diff([{4, "K"}, {60, "k"}])   # kings on their starting squares
  |> Qi.board_diff([{0, "R"}, {63, "r"}])    # rooks in the corners
  |> Qi.toggle()                              # switch turn to second player

pos2.turn              #=> :second
elem(pos2.board, 4)    #=> "K"
elem(pos2.board, 60)   #=> "k"
```

Every transformation returns a **new struct**. The original is never modified.

## Overview

`Qi` models a board game position as defined by the [Sashité Game Protocol](https://sashite.dev/game-protocol/). A position encodes exactly four things:

| Component | Fields | Description |
|-----------|--------|-------------|
| Board | `board` | Flat tuple of squares, indexed in row-major order |
| Hands | `first_player_hand`, `second_player_hand` | Off-board pieces held by each player |
| Styles | `first_player_style`, `second_player_style` | One style string per player side |
| Turn | `turn` | The active player (`:first` or `:second`) |

**Pieces and styles are strings.** Every piece — whether on the board or in a hand — and every style value is stored as a `String`. This aligns naturally with the notation formats in the Sashité ecosystem ([FEEN](https://sashite.dev/specs/feen/1.0.0/), [EPIN](https://sashite.dev/specs/epin/1.0.0/), [PON](https://sashite.dev/specs/pon/1.0.0/), [SIN](https://sashite.dev/specs/sin/1.0.0/)), which all produce string representations. Empty squares are represented by `nil`.

**Strings required.** Pieces and styles must be strings (`String.t()`). Non-string values are rejected with an `ArgumentError`. This avoids per-operation coercion overhead on the hot path.

```elixir
pos |> Qi.board_diff([{0, "K"}])         # String — stored as "K"
pos |> Qi.board_diff([{0, "C:K"}])       # Namespaced — stored as "C:K"
pos |> Qi.board_diff([{0, "+P"}])        # Promoted — stored as "+P"
```

## Installation

```elixir
# In mix.exs
def deps do
  [{:qi, "~> 3.0"}]
end
```

Then run:

```sh
mix deps.get
```

### Requirements

`Qi` requires **Elixir 1.14+** / **OTP 25+** (tested against Elixir 1.14 through 1.19 and OTP 25 through 28) and has **zero runtime dependencies**.

## API Reference

### Construction

#### `Qi.new(shape, opts)` → `%Qi{}`

Creates a position with an empty board.

**Parameters:**

- `shape` — a list of one to three integer dimension sizes (each 1–255). The total number of squares (product of dimensions) must not exceed 65,025.
- `:first_player_style` — style for the first player (non-nil string, at most 255 bytes).
- `:second_player_style` — style for the second player (non-nil string, at most 255 bytes).

The board starts with all squares empty (`nil`), both hands start empty, and the turn defaults to `:first`.

```elixir
Qi.new([8, 8], first_player_style: "C", second_player_style: "c")       # 2D (8×8)
Qi.new([8], first_player_style: "G", second_player_style: "g")          # 1D
Qi.new([5, 5, 5], first_player_style: "R", second_player_style: "r")   # 3D
```

**Raises** `ArgumentError` if shape constraints are violated, if total squares exceed the limit, or if a style is `nil` or oversized (see [Validation Errors](#validation-errors)).

### Constants

| Function | Value | Description |
|----------|-------|-------------|
| `Qi.max_dimensions()` | `3` | Maximum number of board dimensions |
| `Qi.max_dimension_size()` | `255` | Maximum size of any single dimension |
| `Qi.max_square_count()` | `65025` | Maximum total number of squares on a board |
| `Qi.max_piece_bytesize()` | `255` | Maximum bytesize of a piece string |
| `Qi.max_style_bytesize()` | `255` | Maximum bytesize of a style string |

### Accessors

All public fields are accessible directly on the struct. The type is opaque — access internal fields only through the documented API.

| Field | Type | Description |
|-------|------|-------------|
| `board` | `tuple()` | Flat tuple of `nil` or `String.t()`. Indexed in row-major order. |
| `first_player_hand` | `%{String.t() => pos_integer()}` | First player's held pieces as piece → count map. |
| `second_player_hand` | `%{String.t() => pos_integer()}` | Second player's held pieces as piece → count map. |
| `turn` | `:first \| :second` | The active player. |
| `first_player_style` | `String.t()` | First player's style. |
| `second_player_style` | `String.t()` | Second player's style. |
| `shape` | `[pos_integer()]` | Board dimensions (e.g., `[8, 8]`). |

```elixir
pos.board                #=> {nil, "r", "n", "b", "q", "k", nil, nil, ...}
pos.first_player_hand    #=> %{}
pos.second_player_hand   #=> %{}
pos.turn                 #=> :first
pos.first_player_style   #=> "C"
pos.second_player_style  #=> "c"
pos.shape                #=> [8, 8]
```

**Board as nested list.** Use `Qi.to_nested/1` to convert the flat tuple into a nested list matching the shape. This is an O(n) operation intended for display or serialization, not for the hot path.

```elixir
Qi.to_nested(pos)  #=> [["r", "n", "b", ...], ...]
```

### Transformations

All transformation functions return a **new `%Qi{}` struct**. The original is never modified.

#### `Qi.board_diff(qi, changes)` → `%Qi{}`

Returns a new position with modified squares.

Accepts a list of `{flat_index, piece}` tuples where each flat index is a 0-based integer in row-major order, and each piece is a string (at most 255 bytes) or `nil` (empty square).

```elixir
pos2 = Qi.board_diff(pos, [{12, nil}, {28, "P"}])
```

**Raises** `ArgumentError` if an index is out of range, if a piece exceeds 255 bytes, or if the resulting total piece count exceeds the board size.

See [Flat Indexing](#flat-indexing) for computing flat indices from coordinates.

#### `Qi.first_player_hand_diff(qi, changes)` → `%Qi{}`
#### `Qi.second_player_hand_diff(qi, changes)` → `%Qi{}`

Returns a new position with a modified hand.

Accepts a list of `{piece, delta}` tuples where each piece is a string (at most 255 bytes) and each delta is an integer (positive to add, negative to remove, zero is a no-op).

```elixir
pos2 = Qi.first_player_hand_diff(pos, [{"P", 1}])               # Add one "P"
pos3 = Qi.first_player_hand_diff(pos, [{"B", -1}, {"P", 1}])    # Remove one "B", add one "P"
pos4 = Qi.second_player_hand_diff(pos, [{"p", 1}])              # Add one "p" to second hand
```

Internally, hands are stored as `%{piece => count}` maps. Adding and removing pieces is O(1) per entry.

**Raises** `ArgumentError` if a delta is not an integer, if a piece exceeds 255 bytes, if removing a piece not present, or if the resulting total piece count exceeds the board size.

#### `Qi.toggle(qi)` → `%Qi{}`

Returns a new position with the active player swapped. All other fields are preserved.

```elixir
pos.turn                #=> :first
Qi.toggle(pos).turn     #=> :second
```

#### Piping

Transformations compose naturally with the pipe operator. A typical move involves modifying the board, optionally updating a hand, and toggling the turn:

```elixir
# Simple move: slide a piece from index 12 to index 28
pos2 =
  pos
  |> Qi.board_diff([{12, nil}, {28, "P"}])
  |> Qi.toggle()

# Capture: overwrite defender, add captured piece to hand, toggle
pos3 =
  pos
  |> Qi.board_diff([{12, nil}, {28, "P"}])
  |> Qi.first_player_hand_diff([{"p", 1}])
  |> Qi.toggle()
```

The Protocol does not prescribe how captures are modeled. In the example above, `board_diff` simultaneously vacates the source and overwrites the destination. The captured piece must be added to the hand separately — `board_diff` does not track what was previously on a square.

## Board Structure

### Shape and Dimensionality

The `board` field is always a flat tuple. Use `Qi.to_nested/1` when a nested structure is needed:

| Dimensionality | Constructor | `Qi.to_nested/1` returns |
|----------------|-------------|--------------------------|
| 1D | `Qi.new([8], ...)` | `[square, square, ...]` |
| 2D | `Qi.new([8, 8], ...)` | `[[square, ...], [square, ...], ...]` |
| 3D | `Qi.new([5, 5, 5], ...)` | `[[[square, ...], ...], ...]` |

Each `square` is either `nil` (empty) or a string (a piece).

For a shape `[d1, d2, ..., dn]`, the total number of squares is `d1 × d2 × ... × dn`. This total must not exceed 65,025 (`max_square_count/0`).

### Flat Indexing

`board_diff` addresses squares by **flat index** — a single integer in **row-major order** (C order). Individual squares can also be read directly from the board tuple via `elem(pos.board, index)`.

**1D board** with shape `[f]`:

```
flat_index = f
```

**2D board** with shape `[r, f]` (r ranks, f files):

```
flat_index = r × F + f
```

For example, on a 3×3 board (shape `[3, 3]`):

```
             file
           0   1   2
        ┌────┬────┬────┐
rank 0  │  0 │  1 │  2 │
        ├────┼────┼────┤
rank 1  │  3 │  4 │  5 │
        ├────┼────┼────┤
rank 2  │  6 │  7 │  8 │
        └────┴────┴────┘
```

Square `(rank=1, file=2)` → flat index `1 × 3 + 2 = 5`.

**3D board** with shape `[l, r, f]` (l layers, r ranks, f files):

```
flat_index = l × R × F + r × F + f
```

### Piece Cardinality

The total number of pieces across all locations (board squares + both hands) must never exceed the number of squares on the board. This invariant is enforced on every transformation.

For a board with *n* squares and *p* total pieces: **0 ≤ p ≤ n**.

```elixir
pos =
  Qi.new([2], first_player_style: "C", second_player_style: "c")
  |> Qi.board_diff([{0, "a"}, {1, "b"}])   # 2 pieces on 2 squares: OK

Qi.first_player_hand_diff(pos, [{"c", 1}])
# ** (ArgumentError) too many pieces for board size (3 pieces, 2 squares)
```

## Validation Errors

### Validation Order

Construction validates fields in a guaranteed order. When multiple errors exist, the **first** failing check determines the error message:

1. **Shape** — dimension count, types, bounds, then total square count
2. **Styles** — nil checks (first, then second), then type checks, then bytesize checks

This order is part of the public API contract.

### Construction Errors

| Error message | Cause |
|---------------|-------|
| `"at least one dimension is required"` | Empty shape list |
| `"board exceeds 3 dimensions (got N)"` | More than 3 dimension sizes |
| `"dimension size must be an integer, got T"` | Non-integer dimension size |
| `"dimension size must be at least 1, got N"` | Dimension size is zero or negative |
| `"dimension size N exceeds maximum of 255"` | Dimension size exceeds 255 |
| `"board exceeds 65025 squares (got N)"` | Total square count exceeds limit |
| `"first player style must not be nil"` | First style is `nil` |
| `"second player style must not be nil"` | Second style is `nil` |
| `"first player style must be a String"` | First style is not a String |
| `"second player style must be a String"` | Second style is not a String |
| `"first player style exceeds 255 bytes"` | First style is too large |
| `"second player style exceeds 255 bytes"` | Second style is too large |

### Transformation Errors

| Error message | Function | Cause |
|---------------|----------|-------|
| `"invalid flat index: I (board has N squares)"` | `board_diff` | Index out of range or non-integer key |
| `"piece must be a string or nil, got T"` | `board_diff` | Non-string piece value |
| `"piece exceeds 255 bytes (got N)"` | `board_diff`, hand diffs | Piece string too large |
| `"piece must be a string, got T"` | hand diffs | Non-string piece key |
| `"delta must be an integer, got T for piece P"` | hand diffs | Non-integer delta |
| `"cannot remove P: not found in hand"` | hand diffs | Removing more pieces than present |
| `"too many pieces for board size (P pieces, N squares)"` | all | Total pieces would exceed board capacity |

## Design Principles

**Immutable by nature.** Elixir data structures are immutable by default. Every `%Qi{}` struct is a value — transformation functions return new structs rather than mutating state. This eliminates an entire class of bugs around shared mutable state and makes positions safe to use as map keys, cache entries, or history snapshots.

**Bounded resource consumption.** All inputs are bounded: board dimensions (1–255 per axis, 65,025 total squares), piece strings (255 bytes), style strings (255 bytes). No input can trigger unbounded memory allocation. The library is safe to use in an internet-facing service with zero additional sanitization by the caller.

**Performance-oriented internals.** The board is stored as a flat tuple for O(1) random access via `elem/2` and efficient updates via `put_elem/3`. Hands are stored as `%{piece => count}` maps for O(1) additions and removals. Transformations accept lists of tuples — lightweight to allocate and fast to iterate — rather than maps. String validation replaces coercion to avoid per-operation protocol dispatch.

**Diff-based transformations.** Rather than rebuilding a full position from scratch, `board_diff` and hand diff functions express changes as deltas against the current state. This keeps the API surface small (four transformation functions cover all possible state transitions) while making the intent of each operation explicit.

**Zero dependencies.** `Qi` relies only on the Elixir standard library. No transitive dependency tree to audit, no version conflicts to resolve.

## Concurrency

`%Qi{}` structs are plain Elixir data — fully immutable and safe to share across processes without synchronization. They can be sent in messages, stored in ETS, or held in GenServer state without risk of data races.

## Ecosystem

`Qi` is the positional core of the [Sashité](https://sashite.dev/) ecosystem. It models *what a position is* (board, hands, styles, turn) without prescribing *how positions are serialized* or *what moves are legal*.

Other libraries in the ecosystem build on `Qi` to provide those capabilities: [FEEN](https://sashite.dev/specs/feen/1.0.0/) defines a canonical string encoding for positions, [PON](https://sashite.dev/specs/pon/1.0.0/) provides a JSON-based position format, [EPIN](https://sashite.dev/specs/epin/1.0.0/) specifies piece token syntax, and [SIN](https://sashite.dev/specs/sin/1.0.0/) specifies style token syntax. The [Game Protocol](https://sashite.dev/game-protocol/) describes the conceptual foundation that all these specifications share.

## Notes for Reimplementors

This section provides guidance for porting `Qi` to other languages.

### API Surface

The complete public API consists of:

- **1 constructor** — `Qi.new/2`
- **7 accessors** — `board`, `first_player_hand`, `second_player_hand`, `turn`, `first_player_style`, `second_player_style`, `shape` (struct fields)
- **5 functions** — `board_diff/2`, `first_player_hand_diff/2`, `second_player_hand_diff/2`, `toggle/1`, `to_nested/1`
- **5 constants** — `max_dimensions/0`, `max_dimension_size/0`, `max_square_count/0`, `max_piece_bytesize/0`, `max_style_bytesize/0`

### Key Semantic Contracts

**Pieces and styles are strings.** Board squares, hand contents, and style values are all stored as strings. Non-string inputs are rejected at the boundary.

**All inputs are bounded.** Dimensions are capped at 255, total squares at 65,025, piece strings at 255 bytes, style strings at 255 bytes. No input can trigger unbounded memory allocation. Reimplementations must enforce these same limits to maintain the security properties.

**Piece equality is by value.** Hand operations use standard Elixir `==` for piece matching.

**Piece cardinality is global.** The constraint `p ≤ n` counts pieces across all locations: board squares plus both hands. A transformation that adds a piece to a hand can exceed the limit even if the board has empty squares.

**Nil means empty.** On the board, `nil` represents an empty square. Styles must not be nil — this is the only nil-related error at construction.

**Validation order is guaranteed**: shape (dimensions → total square count) → styles (nil → type → bytesize). Tests assert which error is reported when multiple inputs are invalid simultaneously.

**Hands are piece → count maps.** Internally, hands use `%{"P" => 2, "B" => 1}` rather than flat lists. This gives O(1) add/remove and makes count queries trivial. Empty entries (count reaching zero) are removed from the map.

**The constructor creates an empty position**: board all nil, hands empty, turn is first player. Pieces are added via `board_diff/2` and hand diff functions.

**The type is opaque.** `Qi.t()` is declared `@opaque`. Consumers should access fields only through the documented API. Direct construction of `%Qi{}` structs or modification of internal fields bypasses validation and may corrupt invariants. Dialyzer reports violations of this contract.

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
