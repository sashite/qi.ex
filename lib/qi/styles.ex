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

  @max_style_bytesize 255

  @doc "Maximum bytesize of a style string."
  @spec max_style_bytesize() :: pos_integer()
  def max_style_bytesize, do: @max_style_bytesize

  @doc """
  Validates a single player style.

  Returns `:ok` if the style is a non-nil string of at most
  #{@max_style_bytesize} bytes, or `{:error, Exception.t()}` otherwise.

  Validation order: nil → type → bytesize.

  ## Examples

      iex> Qi.Styles.validate(:first, "C")
      :ok

      iex> Qi.Styles.validate(:second, "shogi")
      :ok

      iex> Qi.Styles.validate(:first, nil)
      {:error, %ArgumentError{message: "first player style must not be nil"}}

      iex> Qi.Styles.validate(:second, :chess)
      {:error, %ArgumentError{message: "second player style must be a String"}}

      iex> Qi.Styles.validate(:first, String.duplicate("A", 256))
      {:error, %ArgumentError{message: "first player style exceeds 255 bytes"}}
  """
  @spec validate(:first | :second, term()) :: :ok | {:error, Exception.t()}
  def validate(_side, style) when is_binary(style) and byte_size(style) <= @max_style_bytesize,
    do: :ok

  def validate(side, style) when is_binary(style) do
    {:error, %ArgumentError{message: "#{side} player style exceeds #{@max_style_bytesize} bytes"}}
  end

  def validate(side, nil) do
    {:error, %ArgumentError{message: "#{side} player style must not be nil"}}
  end

  def validate(side, _style) do
    {:error, %ArgumentError{message: "#{side} player style must be a String"}}
  end
end
