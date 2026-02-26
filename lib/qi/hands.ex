defmodule Qi.Hands do
  @moduledoc """
  Pure validation functions for player hands.

  Hands are represented as a map with exactly two keys:

    * `:first` — list of pieces held by the first player.
    * `:second` — list of pieces held by the second player.

  Each piece in a hand can be any non-nil term. The ordering of pieces
  within a hand carries no semantic meaning.

  ## Examples

      iex> Qi.Hands.validate(%{first: ["+P", "+P"], second: ["b"]})
      {:ok, 3}

      iex> Qi.Hands.validate(%{first: [], second: []})
      {:ok, 0}
  """

  @typedoc "A pair of hands, one per player side."
  @type t :: %{first: [term()], second: [term()]}

  @doc """
  Validates hands structure and returns the total piece count.

  Returns `{:ok, piece_count}` if the hands are valid, or
  `{:error, %ArgumentError{}}` otherwise.

  Validation checks shape (exactly two keys), type (both values are lists),
  then performs a single pass over each list to reject `nil` elements and
  count pieces simultaneously.

  ## Examples

      iex> Qi.Hands.validate(%{first: [:P, :B], second: [:p]})
      {:ok, 3}

      iex> Qi.Hands.validate(%{first: [nil], second: []})
      {:error, %ArgumentError{message: "hand pieces must not be nil"}}

      iex> Qi.Hands.validate(%{first: []})
      {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}}
  """
  @spec validate(term()) :: {:ok, non_neg_integer()} | {:error, Exception.t()}
  def validate(hands) do
    with :ok <- validate_shape(hands),
         :ok <- validate_lists(hands) do
      count_and_validate_pieces(hands.first, hands.second)
    end
  end

  defp validate_shape(%{first: _, second: _} = map) when map_size(map) == 2, do: :ok

  defp validate_shape(hands) when is_map(hands) do
    {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}}
  end

  defp validate_shape(_) do
    {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}}
  end

  defp validate_lists(%{first: first, second: second})
       when is_list(first) and is_list(second),
       do: :ok

  defp validate_lists(_) do
    {:error, %ArgumentError{message: "each hand must be a list"}}
  end

  # Single pass: reject nil pieces and count simultaneously for both hands.

  defp count_and_validate_pieces(first, second) do
    with {:ok, first_count} <- count_hand(first) do
      case count_hand(second) do
        {:ok, second_count} -> {:ok, first_count + second_count}
        error -> error
      end
    end
  end

  defp count_hand(pieces), do: count_hand(pieces, 0)

  defp count_hand([], acc), do: {:ok, acc}

  defp count_hand([nil | _], _acc),
    do: {:error, %ArgumentError{message: "hand pieces must not be nil"}}

  defp count_hand([_ | tail], acc), do: count_hand(tail, acc + 1)
end
