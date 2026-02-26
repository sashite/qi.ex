defmodule Qi do
  @moduledoc """
  A minimal, format-agnostic library for representing positions in
  two-player, turn-based board games.

  `Qi` models the four components of a position as defined by the
  Sashité Game Protocol:

    * **Board** — a multi-dimensional rectangular grid (1D, 2D, or 3D)
      where each square is either empty (`nil`) or occupied by a piece
      (any non-nil term).
    * **Hands** — collections of off-board pieces held by each player.
    * **Styles** — one style value per player side (format-free).
    * **Turn** — which player is active (`:first` or `:second`).

  Piece and style representations are intentionally opaque: `Qi` validates
  structure, not semantics. This makes the library reusable across FEEN,
  PON, or any other encoding that shares the same positional model.

  ## Constraints

  | Constraint          | Value | Rationale                                      |
  |---------------------|-------|-------------------------------------------------|
  | Max dimensions      | 3     | Covers 1D, 2D, 3D boards                       |
  | Max dimension size  | 255   | Fits in 8-bit integer; covers 255×255×255       |
  | Board non-empty     | n ≥ 1 | A board must contain at least one square        |
  | Piece cardinality   | p ≤ n | Pieces cannot exceed the number of squares      |

  ## Examples

  A 3×3 board with two kings and a pawn in hand:

      iex> board = [[nil, nil, nil], [nil, "K^", nil], [nil, nil, "k^"]]
      iex> hands = %{first: ["+P"], second: []}
      iex> {:ok, pos} = Qi.new(board, hands, %{first: "C", second: "c"}, :first)
      iex> pos.turn
      :first
      iex> pos.hands.first
      ["+P"]
  """

  alias Qi.Position

  @doc """
  Creates a new position after validating all structural constraints.

  Returns `{:ok, %Qi.Position{}}` on success, or `{:error, %ArgumentError{}}`
  on failure.

  ## Parameters

    * `board` — nested list representing the board (1D to 3D).
    * `hands` — `%{first: list, second: list}` of off-board pieces.
    * `styles` — `%{first: term, second: term}` of player styles.
    * `turn` — `:first` or `:second`.

  ## Examples

  A valid position:

      iex> Qi.new([[:a, nil], [nil, :b]], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
      {:ok, %Qi.Position{board: [[:a, nil], [nil, :b]], hands: %{first: [], second: []}, styles: %{first: "C", second: "c"}, turn: :first}}

  An invalid position (too many pieces for the board):

      iex> Qi.new([:k], %{first: [:P], second: []}, %{first: "C", second: "c"}, :first)
      {:error, %ArgumentError{message: "too many pieces for board size (2 pieces, 1 squares)"}}
  """
  @spec new(Qi.Board.t(), Qi.Hands.t(), Qi.Styles.t(), :first | :second) ::
          {:ok, Position.t()} | {:error, Exception.t()}
  def new(board, hands, styles, turn) do
    Position.new(board, hands, styles, turn)
  end

  @doc """
  Like `new/4`, but raises `ArgumentError` on invalid input.

  ## Examples

      iex> pos = Qi.new!([[nil, "k^"], ["K^", nil]], %{first: [], second: []}, %{first: "S", second: "s"}, :second)
      iex> pos.turn
      :second

      iex> Qi.new!([], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
      ** (ArgumentError) board must not be empty
  """
  @spec new!(Qi.Board.t(), Qi.Hands.t(), Qi.Styles.t(), :first | :second) :: Position.t()
  def new!(board, hands, styles, turn) do
    case new(board, hands, styles, turn) do
      {:ok, position} -> position
      {:error, error} -> raise error
    end
  end
end
