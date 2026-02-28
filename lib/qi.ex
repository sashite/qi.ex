defmodule Qi do
  @moduledoc """
  A minimal, format-agnostic library for representing positions in
  two-player, turn-based board games.

  `Qi` models the four components of a position as defined by the
  Sashité Game Protocol:

    * **Board** — a flat tuple in row-major order (1D, 2D, or 3D)
      where each element is either empty (`nil`) or occupied by a
      piece (`String.t()`).
    * **Hands** — `%{String.t() => pos_integer()}` maps of held pieces
      for each player.
    * **Styles** — one style `String.t()` per player side.
    * **Turn** — which player is active (`:first` or `:second`).

  Pieces and styles must be strings. Non-string values are rejected at
  the boundary.

  ## Construction

  `Qi.new/2` creates a position with an empty board, empty hands, and
  the turn set to `:first`:

      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")

  ## Transformations

  All transformation functions return a new `%Qi{}` struct. The original
  is never modified. Transformations compose naturally with the pipe
  operator:

      pos2 =
        pos
        |> Qi.board_diff([{12, nil}, {28, "P"}])
        |> Qi.first_player_hand_diff([{"p", 1}])
        |> Qi.toggle()

  ## Constraints

  | Constraint          | Value | Rationale                                      |
  |---------------------|-------|-------------------------------------------------|
  | Max dimensions      | 3     | Covers 1D, 2D, 3D boards                       |
  | Max dimension size  | 255   | Fits in 8-bit integer; covers 255×255×255       |
  | Board non-empty     | n ≥ 1 | A board must contain at least one square        |
  | Piece cardinality   | p ≤ n | Pieces cannot exceed the number of squares      |
  """

  alias Qi.Board
  alias Qi.Hands
  alias Qi.Styles

  # Public fields (documented in README):
  #   board, first_player_hand, second_player_hand, turn,
  #   first_player_style, second_player_style, shape
  #
  # Internal fields (used for incremental piece count tracking):
  #   square_count, board_piece_count, first_hand_count, second_hand_count

  @enforce_keys [
    :board,
    :first_player_hand,
    :second_player_hand,
    :turn,
    :first_player_style,
    :second_player_style,
    :shape,
    :square_count,
    :board_piece_count,
    :first_hand_count,
    :second_hand_count
  ]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          board: tuple(),
          first_player_hand: Hands.t(),
          second_player_hand: Hands.t(),
          turn: :first | :second,
          first_player_style: String.t(),
          second_player_style: String.t(),
          shape: [pos_integer()],
          square_count: pos_integer(),
          board_piece_count: non_neg_integer(),
          first_hand_count: non_neg_integer(),
          second_hand_count: non_neg_integer()
        }

  # ---------------------------------------------------------------------------
  # Constants
  # ---------------------------------------------------------------------------

  @doc "Maximum number of board dimensions."
  @spec max_dimensions() :: pos_integer()
  def max_dimensions, do: Board.max_dimensions()

  @doc "Maximum size of any single dimension."
  @spec max_dimension_size() :: pos_integer()
  def max_dimension_size, do: Board.max_dimension_size()

  # ---------------------------------------------------------------------------
  # Construction
  # ---------------------------------------------------------------------------

  @doc """
  Creates a position with an empty board.

  The board starts with all squares empty (`nil`), both hands start
  empty, and the turn defaults to `:first`.

  Validation order is guaranteed: **shape**, then **styles** (first,
  then second). When multiple errors exist, the first failing check
  determines the error.

  ## Parameters

    * `shape` — a list of 1 to 3 integer dimension sizes (each 1–255).
    * `:first_player_style` — style for the first player (non-nil string).
    * `:second_player_style` — style for the second player (non-nil string).

  ## Examples

      iex> pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      iex> pos.turn
      :first
      iex> pos.shape
      [8, 8]
      iex> pos.first_player_style
      "C"

      iex> Qi.new([], first_player_style: "C", second_player_style: "c")
      ** (ArgumentError) at least one dimension is required

      iex> Qi.new([8, 8], first_player_style: nil, second_player_style: "c")
      ** (ArgumentError) first player style must not be nil
  """
  @spec new([pos_integer()], [
          {:first_player_style, String.t()} | {:second_player_style, String.t()}
        ]) :: t()
  def new(shape, opts) do
    square_count = validate!(Board.validate_shape(shape))

    first_style = Keyword.fetch!(opts, :first_player_style)
    second_style = Keyword.fetch!(opts, :second_player_style)
    validate!(Styles.validate(:first, first_style))
    validate!(Styles.validate(:second, second_style))

    %__MODULE__{
      board: Board.new(square_count),
      first_player_hand: Hands.new(),
      second_player_hand: Hands.new(),
      turn: :first,
      first_player_style: first_style,
      second_player_style: second_style,
      shape: shape,
      square_count: square_count,
      board_piece_count: 0,
      first_hand_count: 0,
      second_hand_count: 0
    }
  end

  # ---------------------------------------------------------------------------
  # Transformations
  # ---------------------------------------------------------------------------

  @doc """
  Returns a new position with modified squares on the board.

  Accepts a list of `{flat_index, piece}` tuples where each flat index
  is a 0-based integer in row-major order, and each piece is a string
  or `nil` (empty square).

  ## Examples

      iex> pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      iex> pos2 = Qi.board_diff(pos, [{0, "K"}, {3, "k"}])
      iex> elem(pos2.board, 0)
      "K"
      iex> elem(pos2.board, 3)
      "k"

      iex> pos = Qi.new([2], first_player_style: "C", second_player_style: "c")
      iex> pos = Qi.board_diff(pos, [{0, "a"}, {1, "b"}])
      iex> Qi.first_player_hand_diff(pos, [{"c", 1}])
      ** (ArgumentError) too many pieces for board size (3 pieces, 2 squares)
  """
  @spec board_diff(t(), [{non_neg_integer(), String.t() | nil}]) :: t()
  def board_diff(%__MODULE__{} = qi, changes) do
    {new_board, delta} = validate!(Board.diff(qi.board, changes))

    new_board_piece_count = qi.board_piece_count + delta
    total = new_board_piece_count + qi.first_hand_count + qi.second_hand_count
    validate_cardinality!(total, qi.square_count)

    %{qi | board: new_board, board_piece_count: new_board_piece_count}
  end

  @doc """
  Returns a new position with the first player's hand modified.

  Accepts a list of `{piece, delta}` tuples where each piece is a
  string and each delta is an integer (positive to add, negative to
  remove, zero is a no-op).

  ## Examples

      iex> pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      iex> pos2 = Qi.first_player_hand_diff(pos, [{"P", 2}, {"B", 1}])
      iex> pos2.first_player_hand
      %{"P" => 2, "B" => 1}
  """
  @spec first_player_hand_diff(t(), [{String.t(), integer()}]) :: t()
  def first_player_hand_diff(%__MODULE__{} = qi, changes) do
    {new_hand, delta} = validate!(Hands.diff(qi.first_player_hand, changes))

    new_count = qi.first_hand_count + delta
    total = qi.board_piece_count + new_count + qi.second_hand_count
    validate_cardinality!(total, qi.square_count)

    %{qi | first_player_hand: new_hand, first_hand_count: new_count}
  end

  @doc """
  Returns a new position with the second player's hand modified.

  Accepts a list of `{piece, delta}` tuples where each piece is a
  string and each delta is an integer (positive to add, negative to
  remove, zero is a no-op).

  ## Examples

      iex> pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      iex> pos2 = Qi.second_player_hand_diff(pos, [{"p", 1}])
      iex> pos2.second_player_hand
      %{"p" => 1}
  """
  @spec second_player_hand_diff(t(), [{String.t(), integer()}]) :: t()
  def second_player_hand_diff(%__MODULE__{} = qi, changes) do
    {new_hand, delta} = validate!(Hands.diff(qi.second_player_hand, changes))

    new_count = qi.second_hand_count + delta
    total = qi.board_piece_count + qi.first_hand_count + new_count
    validate_cardinality!(total, qi.square_count)

    %{qi | second_player_hand: new_hand, second_hand_count: new_count}
  end

  @doc """
  Returns a new position with the active player swapped.

  All other fields are preserved unchanged.

  ## Examples

      iex> pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      iex> pos.turn
      :first
      iex> Qi.toggle(pos).turn
      :second
      iex> pos |> Qi.toggle() |> Qi.toggle() |> Map.get(:turn)
      :first
  """
  @spec toggle(t()) :: t()
  def toggle(%__MODULE__{turn: :first} = qi), do: %{qi | turn: :second}
  def toggle(%__MODULE__{turn: :second} = qi), do: %{qi | turn: :first}

  # ---------------------------------------------------------------------------
  # Conversion
  # ---------------------------------------------------------------------------

  @doc """
  Converts the flat board tuple into a nested list matching the shape.

  This is an O(n) operation intended for display or serialization, not
  for the hot path.

  ## Examples

      iex> pos = Qi.new([2, 3], first_player_style: "C", second_player_style: "c")
      iex> pos = Qi.board_diff(pos, [{0, "a"}, {5, "b"}])
      iex> Qi.to_nested(pos)
      [["a", nil, nil], [nil, nil, "b"]]
  """
  @spec to_nested(t()) :: list()
  def to_nested(%__MODULE__{} = qi) do
    Board.to_nested(qi.board, qi.shape)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Unwraps {:ok, value} or raises on {:error, %ArgumentError{}}.
  # Used at the boundary to convert tagged tuples into raise semantics.
  defp validate!(:ok), do: nil
  defp validate!({:ok, value}), do: value
  defp validate!({:ok, value1, value2}), do: {value1, value2}
  defp validate!({:error, %ArgumentError{} = error}), do: raise(error)

  defp validate_cardinality!(total, square_count) when total <= square_count, do: :ok

  defp validate_cardinality!(total, square_count) do
    raise ArgumentError,
          "too many pieces for board size (#{total} pieces, #{square_count} squares)"
  end
end
