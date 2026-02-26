defmodule Qi.Board do
  @moduledoc """
  Pure validation functions for multi-dimensional board structures.

  A board is represented as a nested list where:

    * A **1D board** is a flat list of squares: `[nil, "K^", nil]`
    * A **2D board** is a list of ranks: `[[nil, nil], ["K^", nil]]`
    * A **3D board** is a list of layers, each a list of ranks.

  Each leaf element (square) is either `nil` (empty) or any non-nil term (a piece).

  ## Constraints

    * Maximum dimensionality: 3
    * Maximum size per dimension: 255
    * At least one square (non-empty board)
    * Rectangular structure: all sub-arrays at the same depth must have
      identical length (enforced globally, not just per-sibling).

  ## Examples

      iex> Qi.Board.validate([[:a, nil], [nil, :b]])
      {:ok, {4, 2}}

      iex> Qi.Board.validate([[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]])
      {:ok, {9, 0}}
  """

  @max_dimensions 3
  @max_dimension_size 255

  @typedoc "A square is either empty (nil) or occupied by any piece term."
  @type square :: nil | term()

  @typedoc "A board is a (possibly nested) list of squares."
  @type t :: [square()] | [[square()]] | [[[square()]]]

  @doc """
  Validates a board and returns its square and piece counts.

  Returns `{:ok, {square_count, piece_count}}` if the board is structurally
  valid, or `{:error, %ArgumentError{}}` otherwise.

  Validation proceeds in order of increasing cost: type check, emptiness,
  shape inference (first-path walk), dimension limits, then a single-pass
  structural verification with counting.

  ## Examples

  A 2D board:

      iex> Qi.Board.validate([[:r, nil, nil], [nil, nil, :R]])
      {:ok, {6, 2}}

  A 1D board:

      iex> Qi.Board.validate([:k, nil, nil, :K])
      {:ok, {4, 2}}

  A 3D board (2 layers × 2 ranks × 2 files):

      iex> Qi.Board.validate([[[:a, nil], [nil, :b]], [[nil, :c], [:d, nil]]])
      {:ok, {8, 4}}

  Non-rectangular boards are rejected:

      iex> Qi.Board.validate([[:a, :b], [:c]])
      {:error, %ArgumentError{message: "non-rectangular board: expected 2 elements, got 1"}}
  """
  @spec validate(term()) ::
          {:ok, {pos_integer(), non_neg_integer()}} | {:error, Exception.t()}
  def validate(board) do
    with :ok <- validate_is_list(board),
         :ok <- validate_non_empty(board),
         {:ok, shape} <- compute_shape(board),
         :ok <- validate_max_dimensions(shape),
         :ok <- validate_dimension_sizes(shape) do
      verify_and_count(board, shape)
    end
  end

  # ---------------------------------------------------------------------------
  # Step 1: basic type checks
  # ---------------------------------------------------------------------------

  defp validate_is_list(board) when is_list(board), do: :ok
  defp validate_is_list(_), do: {:error, %ArgumentError{message: "board must be a list"}}

  defp validate_non_empty([]), do: {:error, %ArgumentError{message: "board must not be empty"}}
  defp validate_non_empty(_), do: :ok

  # ---------------------------------------------------------------------------
  # Step 2: compute expected shape by walking the first element at each level
  # ---------------------------------------------------------------------------

  # The shape is a list of dimension sizes, e.g. [2, 3, 8] for
  # 2 layers × 3 ranks × 8 files. We derive it by following the first
  # child at each nesting level.

  defp compute_shape(board), do: compute_shape(board, [])

  defp compute_shape([first | _] = list, acc) when is_list(first) do
    compute_shape(first, [length(list) | acc])
  end

  defp compute_shape(list, acc) when is_list(list) do
    {:ok, Enum.reverse([length(list) | acc])}
  end

  # ---------------------------------------------------------------------------
  # Step 3: validate dimension count and sizes
  # ---------------------------------------------------------------------------

  defp validate_max_dimensions(shape) do
    dim = length(shape)

    if dim <= @max_dimensions do
      :ok
    else
      {:error,
       %ArgumentError{
         message: "board exceeds #{@max_dimensions} dimensions (got #{dim})"
       }}
    end
  end

  defp validate_dimension_sizes(shape) do
    case Enum.find(shape, fn size -> size > @max_dimension_size end) do
      nil ->
        :ok

      size ->
        {:error,
         %ArgumentError{
           message: "dimension size #{size} exceeds maximum of #{@max_dimension_size}"
         }}
    end
  end

  # ---------------------------------------------------------------------------
  # Step 4: verify structure and count in a single pass
  # ---------------------------------------------------------------------------

  # For a 1D shape [n]: single-pass over the rank, verifying all elements are
  # leaves (not lists) while counting squares and pieces simultaneously.
  defp verify_and_count(board, [n]) do
    verify_and_count_rank(board, n, 0, 0)
  end

  # For a multi-dimensional shape [n | rest]: check length, then recurse
  # into each sub-array, accumulating counts.
  defp verify_and_count(board, [n | rest]) do
    actual = length(board)

    if actual != n do
      error_non_rectangular(n, actual)
    else
      verify_and_count_subs(board, rest, 0, 0)
    end
  end

  # -- Rank-level single pass (innermost dimension) --

  defp verify_and_count_rank([], expected, count, pieces) do
    if count == expected do
      {:ok, {count, pieces}}
    else
      error_non_rectangular(expected, count)
    end
  end

  defp verify_and_count_rank([head | _tail], _expected, _count, _pieces) when is_list(head) do
    {:error,
     %ArgumentError{
       message: "inconsistent board structure: expected flat squares at this level"
     }}
  end

  defp verify_and_count_rank([nil | tail], expected, count, pieces) do
    verify_and_count_rank(tail, expected, count + 1, pieces)
  end

  defp verify_and_count_rank([_piece | tail], expected, count, pieces) do
    verify_and_count_rank(tail, expected, count + 1, pieces + 1)
  end

  # -- Sub-array recursion (outer dimensions) --

  defp verify_and_count_subs([], _shape, sq_acc, pc_acc), do: {:ok, {sq_acc, pc_acc}}

  defp verify_and_count_subs([sub | rest], shape, sq_acc, pc_acc) when is_list(sub) do
    case verify_and_count(sub, shape) do
      {:ok, {sq, pc}} -> verify_and_count_subs(rest, shape, sq_acc + sq, pc_acc + pc)
      error -> error
    end
  end

  defp verify_and_count_subs([_non_list | _rest], _shape, _sq_acc, _pc_acc) do
    {:error,
     %ArgumentError{
       message: "inconsistent board structure: mixed lists and non-lists at same level"
     }}
  end

  # -- Error helper --

  defp error_non_rectangular(expected, actual) do
    {:error,
     %ArgumentError{
       message: "non-rectangular board: expected #{expected} elements, got #{actual}"
     }}
  end
end
