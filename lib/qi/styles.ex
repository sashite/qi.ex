defmodule Qi.Styles do
  @moduledoc """
  Pure validation functions for player styles.

  Styles are represented as a map with exactly two keys:

    * `:first` — the style associated with the first player side.
    * `:second` — the style associated with the second player side.

  Style values are format-free: any non-nil term is accepted.
  Semantic validation (e.g., SIN compliance) is the responsibility
  of the encoding layer (FEEN, PON, etc.), not of `Qi`.

  ## Examples

      iex> Qi.Styles.validate(%{first: "C", second: "c"})
      :ok

      iex> Qi.Styles.validate(%{first: :chess, second: :shogi})
      :ok
  """

  @typedoc "A pair of styles, one per player side."
  @type t :: %{first: term(), second: term()}

  @doc """
  Validates the styles structure.

  Returns `:ok` if the map has exactly keys `:first` and `:second` with
  non-nil values, or `{:error, %ArgumentError{}}` otherwise.

  ## Examples

      iex> Qi.Styles.validate(%{first: "S", second: "s"})
      :ok

      iex> Qi.Styles.validate(%{first: nil, second: "c"})
      {:error, %ArgumentError{message: "first player style must not be nil"}}

      iex> Qi.Styles.validate(%{first: "C", second: nil})
      {:error, %ArgumentError{message: "second player style must not be nil"}}

      iex> Qi.Styles.validate(%{first: "C"})
      {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}}

      iex> Qi.Styles.validate("not a map")
      {:error, %ArgumentError{message: "styles must be a map with keys :first and :second"}}
  """
  @spec validate(term()) :: :ok | {:error, Exception.t()}
  def validate(%{first: first, second: second} = map)
      when map_size(map) == 2 and not is_nil(first) and not is_nil(second),
      do: :ok

  def validate(%{first: nil, second: _} = map) when map_size(map) == 2 do
    {:error, %ArgumentError{message: "first player style must not be nil"}}
  end

  def validate(%{first: _, second: nil} = map) when map_size(map) == 2 do
    {:error, %ArgumentError{message: "second player style must not be nil"}}
  end

  def validate(styles) when is_map(styles) do
    {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}}
  end

  def validate(_) do
    {:error, %ArgumentError{message: "styles must be a map with keys :first and :second"}}
  end
end
