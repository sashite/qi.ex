defmodule Qi.Board do
  @moduledoc """
  Flat-tuple board creation and transformation.

  A board is stored as a flat tuple of `tuple_size` elements in **row-major
  order**. Each element is either `nil` (empty square) or a `String.t()`
  (a piece).

  The board's shape (a list of dimension sizes such as `[8, 8]`) determines
  how flat indices map to multi-dimensional coordinates, but the shape itself
  is stored outside this module (on the `Qi` struct).

  ## Flat indexing (row-major)

    * **1D** `[f]` — `index = f`
    * **2D** `[r, f]` — `index = r * F + f`
    * **3D** `[l, r, f]` — `index = l * R * F + r * F + f`

  ## Performance notes

  `elem/2` is O(1). `put_elem/3` copies the tuple (O(n) where n is the
  number of squares), but the constant factor is very low — it is the
  fastest random-update structure available in the BEAM for fixed-size
  collections.
  """

  @max_dimensions 3
  @max_dimension_size 255
  @max_square_count 65_025
  @max_piece_bytesize 255

  @doc "Maximum number of board dimensions."
  @spec max_dimensions() :: pos_integer()
  def max_dimensions, do: @max_dimensions

  @doc "Maximum size of any single dimension."
  @spec max_dimension_size() :: pos_integer()
  def max_dimension_size, do: @max_dimension_size

  @doc "Maximum total number of squares on a board."
  @spec max_square_count() :: pos_integer()
  def max_square_count, do: @max_square_count

  @doc "Maximum bytesize of a piece string."
  @spec max_piece_bytesize() :: pos_integer()
  def max_piece_bytesize, do: @max_piece_bytesize

  # ---------------------------------------------------------------------------
  # Shape validation
  # ---------------------------------------------------------------------------

  @doc """
  Validates a board shape and returns the total number of squares.

  A shape is a list of 1 to #{@max_dimensions} positive integers, each at
  most #{@max_dimension_size}. The total number of squares (product of all
  dimensions) must not exceed #{@max_square_count}.

  ## Examples

      iex> Qi.Board.validate_shape([8, 8])
      {:ok, 64}

      iex> Qi.Board.validate_shape([9, 9])
      {:ok, 81}

      iex> Qi.Board.validate_shape([5, 5, 5])
      {:ok, 125}

      iex> Qi.Board.validate_shape([])
      {:error, %ArgumentError{message: "at least one dimension is required"}}

      iex> Qi.Board.validate_shape([8, 8, 8, 8])
      {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 4)"}}

      iex> Qi.Board.validate_shape([255, 255, 255])
      {:error, %ArgumentError{message: "board exceeds 65025 squares (got 16581375)"}}
  """
  @spec validate_shape(term()) :: {:ok, pos_integer()} | {:error, Exception.t()}
  def validate_shape(shape) when is_list(shape) and shape != [] do
    with :ok <- validate_dimension_count(shape),
         {:ok, product} <- validate_dimension_values(shape, 1) do
      validate_square_count(product)
    end
  end

  def validate_shape(_) do
    {:error, %ArgumentError{message: "at least one dimension is required"}}
  end

  defp validate_dimension_count(shape) do
    count = length(shape)

    if count <= @max_dimensions do
      :ok
    else
      {:error,
       %ArgumentError{
         message: "board exceeds #{@max_dimensions} dimensions (got #{count})"
       }}
    end
  end

  defp validate_dimension_values([], product), do: {:ok, product}

  defp validate_dimension_values([dim | rest], product)
       when is_integer(dim) and dim >= 1 and dim <= @max_dimension_size do
    validate_dimension_values(rest, product * dim)
  end

  defp validate_dimension_values([dim | _], _) when is_integer(dim) and dim < 1 do
    {:error, %ArgumentError{message: "dimension size must be at least 1, got #{dim}"}}
  end

  defp validate_dimension_values([dim | _], _) when is_integer(dim) do
    {:error,
     %ArgumentError{
       message: "dimension size #{dim} exceeds maximum of #{@max_dimension_size}"
     }}
  end

  defp validate_dimension_values([dim | _], _) do
    {:error,
     %ArgumentError{
       message: "dimension size must be an integer, got #{inspect(dim)}"
     }}
  end

  defp validate_square_count(product) when product <= @max_square_count do
    {:ok, product}
  end

  defp validate_square_count(product) do
    {:error,
     %ArgumentError{
       message: "board exceeds #{@max_square_count} squares (got #{product})"
     }}
  end

  # ---------------------------------------------------------------------------
  # Board creation
  # ---------------------------------------------------------------------------

  @doc """
  Creates an empty board (all `nil`) with the given number of squares.

  ## Examples

      iex> Qi.Board.new(4)
      {nil, nil, nil, nil}
  """
  @spec new(pos_integer()) :: tuple()
  def new(total_squares) when is_integer(total_squares) and total_squares > 0 do
    Tuple.duplicate(nil, total_squares)
  end

  # ---------------------------------------------------------------------------
  # Diff application
  # ---------------------------------------------------------------------------

  @doc """
  Applies a list of changes to a board and returns the piece count delta.

  Each change is a `{flat_index, piece}` tuple where `piece` is a
  `String.t()` (at most #{@max_piece_bytesize} bytes) or `nil` (to clear
  a square).

  Returns `{:ok, new_board, piece_delta}` where `piece_delta` is the net
  change in piece count (positive = pieces added, negative = pieces removed).

  ## Examples

      iex> board = Qi.Board.new(4)
      iex> Qi.Board.diff(board, [{0, "K"}, {3, "k"}])
      {:ok, {"K", nil, nil, "k"}, 2}

      iex> board = {"K", nil, nil, "k"}
      iex> Qi.Board.diff(board, [{0, nil}, {1, "K"}])
      {:ok, {nil, "K", nil, "k"}, 0}

      iex> Qi.Board.diff({nil, nil}, [{5, "K"}])
      {:error, %ArgumentError{message: "invalid flat index: 5 (board has 2 squares)"}}
  """
  @spec diff(tuple(), [{non_neg_integer(), String.t() | nil}]) ::
          {:ok, tuple(), integer()} | {:error, Exception.t()}
  def diff(board, changes) do
    apply_changes(board, changes, tuple_size(board), 0)
  end

  defp apply_changes(board, [], _total, delta), do: {:ok, board, delta}

  defp apply_changes(board, [{index, piece} | rest], total, delta)
       when is_integer(index) and index >= 0 and index < total do
    case validate_piece(piece) do
      :ok ->
        old = elem(board, index)
        new_delta = delta + piece_delta(old, piece)
        apply_changes(put_elem(board, index, piece), rest, total, new_delta)

      {:error, _} = error ->
        error
    end
  end

  defp apply_changes(_board, [{index, _} | _], total, _delta) do
    {:error,
     %ArgumentError{
       message: "invalid flat index: #{inspect(index)} (board has #{total} squares)"
     }}
  end

  defp validate_piece(nil), do: :ok

  defp validate_piece(piece) when is_binary(piece) and byte_size(piece) <= @max_piece_bytesize,
    do: :ok

  defp validate_piece(piece) when is_binary(piece) do
    {:error,
     %ArgumentError{
       message: "piece exceeds #{@max_piece_bytesize} bytes (got #{byte_size(piece)})"
     }}
  end

  defp validate_piece(piece) do
    {:error,
     %ArgumentError{
       message: "piece must be a string or nil, got #{inspect(piece)}"
     }}
  end

  # Net change: nil→string = +1, string→nil = -1, otherwise 0
  defp piece_delta(nil, piece) when is_binary(piece), do: 1
  defp piece_delta(old, nil) when is_binary(old), do: -1
  defp piece_delta(_, _), do: 0

  # ---------------------------------------------------------------------------
  # Piece counting
  # ---------------------------------------------------------------------------

  @doc """
  Counts the number of pieces (non-nil elements) in a board tuple.

  This is an O(n) scan. Prefer tracking the count incrementally via `diff/2`
  on the hot path.

  ## Examples

      iex> Qi.Board.piece_count({nil, "K", nil, "k"})
      2

      iex> Qi.Board.piece_count({nil, nil, nil})
      0
  """
  @spec piece_count(tuple()) :: non_neg_integer()
  def piece_count(board) do
    do_piece_count(board, 0, tuple_size(board), 0)
  end

  defp do_piece_count(_board, index, size, acc) when index == size, do: acc

  defp do_piece_count(board, index, size, acc) do
    case elem(board, index) do
      nil -> do_piece_count(board, index + 1, size, acc)
      _ -> do_piece_count(board, index + 1, size, acc + 1)
    end
  end

  # ---------------------------------------------------------------------------
  # Nested conversion
  # ---------------------------------------------------------------------------

  @doc """
  Converts a flat board tuple into a nested list matching the given shape.

  This is an O(n) operation intended for display or serialization, not for
  the hot path.

  ## Examples

      iex> Qi.Board.to_nested({"a", "b", "c", "d"}, [2, 2])
      [["a", "b"], ["c", "d"]]

      iex> Qi.Board.to_nested({"a", "b", "c"}, [3])
      ["a", "b", "c"]

      iex> Qi.Board.to_nested({nil, nil, nil, nil, nil, nil, nil, nil}, [2, 2, 2])
      [[[nil, nil], [nil, nil]], [[nil, nil], [nil, nil]]]
  """
  @spec to_nested(tuple(), [pos_integer()]) :: list()
  def to_nested(board, [_]) do
    Tuple.to_list(board)
  end

  def to_nested(board, shape) do
    board
    |> Tuple.to_list()
    |> do_nest(shape)
  end

  defp do_nest(flat, [_]), do: flat

  defp do_nest(flat, [_ | rest]) do
    chunk_size = Enum.product(rest)

    flat
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(&do_nest(&1, rest))
  end
end
