defmodule Qi.Position do
  @moduledoc """
  An immutable, validated position for a two-player board game.

  A `Qi.Position` is the in-memory representation of a game position
  as defined by the Sashité Game Protocol. It guarantees that all
  structural invariants hold at construction time.

  ## Fields

    * `board` — multi-dimensional list representing board structure and occupancy.
    * `hands` — `%{first: list, second: list}` of off-board pieces.
    * `styles` — `%{first: term, second: term}` of player styles.
    * `turn` — `:first` or `:second`, the active player's side.

  ## Construction

  Use `Qi.new/4` or `Qi.new!/4` to build positions. Direct struct creation
  via `%Qi.Position{}` bypasses validation and is discouraged.

  ## Examples

      iex> {:ok, pos} = Qi.new([["K^", nil], [nil, "k^"]], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
      iex> pos.board
      [["K^", nil], [nil, "k^"]]
      iex> pos.turn
      :first
  """

  @enforce_keys [:board, :hands, :styles, :turn]
  defstruct [:board, :hands, :styles, :turn]

  @type t :: %__MODULE__{
          board: Qi.Board.t(),
          hands: Qi.Hands.t(),
          styles: Qi.Styles.t(),
          turn: :first | :second
        }

  @doc """
  Creates a validated position.

  Returns `{:ok, %Qi.Position{}}` when all invariants hold, or
  `{:error, %ArgumentError{}}` with a descriptive message otherwise.

  Validation is performed in order of increasing cost: turn (pattern match),
  board (structural traversal), hands, styles, then cardinality.

  ## Validated invariants

    * Turn is `:first` or `:second`.
    * Board is a non-empty, rectangular, nested list (1D to 3D).
    * Each dimension size is at most 255.
    * Hands is a map with `:first` and `:second` lists of non-nil pieces.
    * Styles is a map with `:first` and `:second` non-nil values.
    * Total piece count does not exceed total square count.

  ## Examples

      iex> Qi.Position.new([nil, :k], %{first: [], second: []}, %{first: :chess, second: :chess}, :second)
      {:ok, %Qi.Position{board: [nil, :k], hands: %{first: [], second: []}, styles: %{first: :chess, second: :chess}, turn: :second}}

      iex> Qi.Position.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :third)
      {:error, %ArgumentError{message: "turn must be :first or :second"}}
  """
  @spec new(Qi.Board.t(), Qi.Hands.t(), Qi.Styles.t(), :first | :second) ::
          {:ok, t()} | {:error, Exception.t()}
  def new(board, hands, styles, turn) do
    with :ok <- validate_turn(turn),
         {:ok, {square_count, board_piece_count}} <- Qi.Board.validate(board),
         {:ok, hand_piece_count} <- Qi.Hands.validate(hands),
         :ok <- Qi.Styles.validate(styles),
         :ok <- validate_cardinality(square_count, board_piece_count + hand_piece_count) do
      {:ok, %__MODULE__{board: board, hands: hands, styles: styles, turn: turn}}
    end
  end

  defp validate_turn(:first), do: :ok
  defp validate_turn(:second), do: :ok

  defp validate_turn(_) do
    {:error, %ArgumentError{message: "turn must be :first or :second"}}
  end

  defp validate_cardinality(square_count, piece_count) when piece_count <= square_count, do: :ok

  defp validate_cardinality(square_count, piece_count) do
    {:error,
     %ArgumentError{
       message: "too many pieces for board size (#{piece_count} pieces, #{square_count} squares)"
     }}
  end
end
