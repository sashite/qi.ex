defmodule Qi.Hands do
  @moduledoc """
  Piece-count map operations for a single player hand.

  A hand is represented as a `%{String.t() => pos_integer()}` map where
  keys are piece identifiers and values are the number of held copies.
  An empty hand is an empty map `%{}`.

  Empty entries (count reaching zero) are automatically removed from the
  map to keep it canonical.

  ## Examples

      iex> Qi.Hands.new()
      %{}

      iex> {:ok, hand, 2} = Qi.Hands.diff(%{}, [{"P", 1}, {"B", 1}])
      iex> hand
      %{"B" => 1, "P" => 1}
  """

  @max_piece_bytesize 255

  @doc "Maximum bytesize of a piece string."
  @spec max_piece_bytesize() :: pos_integer()
  def max_piece_bytesize, do: @max_piece_bytesize

  @typedoc "A hand: piece string to positive count."
  @type t :: %{optional(String.t()) => pos_integer()}

  @doc """
  Creates an empty hand.

  ## Examples

      iex> Qi.Hands.new()
      %{}
  """
  @spec new() :: t()
  def new, do: %{}

  # ---------------------------------------------------------------------------
  # Diff application
  # ---------------------------------------------------------------------------

  @doc """
  Applies a list of changes to a hand and returns the piece count delta.

  Each change is a `{piece, delta}` tuple where `piece` is a `String.t()`
  (at most #{@max_piece_bytesize} bytes) and `delta` is an integer
  (positive to add, negative to remove, zero is a no-op). Entries whose
  count reaches zero are removed from the map.

  Returns `{:ok, new_hand, piece_delta}` where `piece_delta` is the net
  change in total piece count.

  ## Examples

      iex> Qi.Hands.diff(%{}, [{"P", 2}, {"B", 1}])
      {:ok, %{"P" => 2, "B" => 1}, 3}

      iex> Qi.Hands.diff(%{"P" => 2}, [{"P", -1}])
      {:ok, %{"P" => 1}, -1}

      iex> Qi.Hands.diff(%{"P" => 1}, [{"P", -1}])
      {:ok, %{}, -1}

      iex> Qi.Hands.diff(%{}, [{"P", 0}])
      {:ok, %{}, 0}

      iex> Qi.Hands.diff(%{"P" => 1}, [{"P", -2}])
      {:error, %ArgumentError{message: "cannot remove P: not found in hand"}}

      iex> Qi.Hands.diff(%{}, [{"P", :one}])
      {:error, %ArgumentError{message: "delta must be an integer, got :one for piece P"}}
  """
  @spec diff(t(), [{String.t(), integer()}]) ::
          {:ok, t(), integer()} | {:error, Exception.t()}
  def diff(hand, changes) do
    apply_changes(hand, changes, 0)
  end

  defp apply_changes(hand, [], delta), do: {:ok, hand, delta}

  defp apply_changes(hand, [{piece, 0} | rest], delta)
       when is_binary(piece) do
    apply_changes(hand, rest, delta)
  end

  defp apply_changes(hand, [{piece, amount} | rest], delta)
       when is_binary(piece) and byte_size(piece) <= @max_piece_bytesize and
              is_integer(amount) do
    current = Map.get(hand, piece, 0)
    new_count = current + amount

    cond do
      new_count > 0 ->
        apply_changes(Map.put(hand, piece, new_count), rest, delta + amount)

      new_count == 0 ->
        apply_changes(Map.delete(hand, piece), rest, delta + amount)

      true ->
        {:error, %ArgumentError{message: "cannot remove #{piece}: not found in hand"}}
    end
  end

  defp apply_changes(_hand, [{piece, amount} | _], _delta)
       when is_binary(piece) and byte_size(piece) > @max_piece_bytesize and
              is_integer(amount) do
    {:error,
     %ArgumentError{
       message: "piece exceeds #{@max_piece_bytesize} bytes (got #{byte_size(piece)})"
     }}
  end

  defp apply_changes(_hand, [{piece, amount} | _], _delta)
       when is_binary(piece) do
    {:error,
     %ArgumentError{
       message: "delta must be an integer, got #{inspect(amount)} for piece #{piece}"
     }}
  end

  defp apply_changes(_hand, [{piece, _} | _], _delta) do
    {:error,
     %ArgumentError{
       message: "piece must be a string, got #{inspect(piece)}"
     }}
  end

  # ---------------------------------------------------------------------------
  # Piece counting
  # ---------------------------------------------------------------------------

  @doc """
  Returns the total number of pieces in a hand.

  ## Examples

      iex> Qi.Hands.piece_count(%{})
      0

      iex> Qi.Hands.piece_count(%{"P" => 3, "B" => 1})
      4
  """
  @spec piece_count(t()) :: non_neg_integer()
  def piece_count(hand) do
    hand
    |> Map.values()
    |> Enum.sum()
  end
end
