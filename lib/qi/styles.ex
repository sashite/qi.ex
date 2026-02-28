defmodule Qi.Styles do
  @moduledoc """
  Pure validation for player style values.

  A style is a `String.t()` label denoting a movement tradition or game
  family (e.g., `"C"`, `"S"`, `"X"`). Semantic validation (e.g., SIN
  compliance) is the responsibility of the encoding layer (FEEN, PON,
  etc.), not of `Qi`.

  ## Examples

      iex> Qi.Styles.validate(:first, "C")
      :ok

      iex> Qi.Styles.validate(:second, nil)
      {:error, %ArgumentError{message: "second player style must not be nil"}}
  """

  @doc """
  Validates a single player style.

  Returns `:ok` if the style is a non-nil string, or
  `{:error, Exception.t()}` otherwise.

  ## Examples

      iex> Qi.Styles.validate(:first, "C")
      :ok

      iex> Qi.Styles.validate(:second, "shogi")
      :ok

      iex> Qi.Styles.validate(:first, nil)
      {:error, %ArgumentError{message: "first player style must not be nil"}}

      iex> Qi.Styles.validate(:second, :chess)
      {:error, %ArgumentError{message: "second player style must be a String"}}
  """
  @spec validate(:first | :second, term()) :: :ok | {:error, Exception.t()}
  def validate(_side, style) when is_binary(style), do: :ok

  def validate(side, nil) do
    {:error, %ArgumentError{message: "#{side} player style must not be nil"}}
  end

  def validate(side, _style) do
    {:error, %ArgumentError{message: "#{side} player style must be a String"}}
  end
end
