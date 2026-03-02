defmodule Qi.StylesTest do
  use ExUnit.Case, async: true

  alias Qi.Styles

  # ===========================================================================
  # Constants
  # ===========================================================================

  describe "max_style_bytesize/0" do
    test "returns 255" do
      assert Styles.max_style_bytesize() == 255
    end
  end

  # ===========================================================================
  # Valid styles
  # ===========================================================================

  describe "validate/2 with valid styles" do
    test "single-character string, first" do
      assert :ok = Styles.validate(:first, "C")
    end

    test "single-character string, second" do
      assert :ok = Styles.validate(:second, "c")
    end

    test "multi-character string" do
      assert :ok = Styles.validate(:first, "chess")
    end

    test "namespaced style" do
      assert :ok = Styles.validate(:first, "Chess960")
    end

    test "empty string" do
      assert :ok = Styles.validate(:first, "")
    end

    test "same style for both sides" do
      assert :ok = Styles.validate(:first, "C")
      assert :ok = Styles.validate(:second, "C")
    end

    test "boundary: exactly 255 bytes" do
      style = String.duplicate("A", 255)
      assert :ok = Styles.validate(:first, style)
      assert :ok = Styles.validate(:second, style)
    end

    test "multi-byte UTF-8 within limit" do
      # "é" is 2 bytes, 127 × 2 = 254 bytes ≤ 255
      style = String.duplicate("é", 127)
      assert :ok = Styles.validate(:first, style)
    end
  end

  # ===========================================================================
  # Invalid styles — nil
  # ===========================================================================

  describe "validate/2 rejects nil" do
    test "first player" do
      assert {:error, %ArgumentError{message: "first player style must not be nil"}} =
               Styles.validate(:first, nil)
    end

    test "second player" do
      assert {:error, %ArgumentError{message: "second player style must not be nil"}} =
               Styles.validate(:second, nil)
    end
  end

  # ===========================================================================
  # Invalid styles — non-string types
  # ===========================================================================

  describe "validate/2 rejects non-string types" do
    test "atom, first" do
      assert {:error, %ArgumentError{message: "first player style must be a String"}} =
               Styles.validate(:first, :chess)
    end

    test "atom, second" do
      assert {:error, %ArgumentError{message: "second player style must be a String"}} =
               Styles.validate(:second, :shogi)
    end

    test "integer" do
      assert {:error, %ArgumentError{message: "first player style must be a String"}} =
               Styles.validate(:first, 1)
    end

    test "boolean" do
      assert {:error, %ArgumentError{message: "first player style must be a String"}} =
               Styles.validate(:first, true)
    end

    test "list" do
      assert {:error, %ArgumentError{message: "second player style must be a String"}} =
               Styles.validate(:second, ["C"])
    end

    test "tuple" do
      assert {:error, %ArgumentError{message: "first player style must be a String"}} =
               Styles.validate(:first, {:variant, "Chess960"})
    end

    test "map" do
      assert {:error, %ArgumentError{message: "second player style must be a String"}} =
               Styles.validate(:second, %{name: "chess"})
    end
  end

  # ===========================================================================
  # Invalid styles — bytesize
  # ===========================================================================

  describe "validate/2 rejects oversized styles" do
    test "first player, 256 bytes" do
      style = String.duplicate("A", 256)

      assert {:error, %ArgumentError{message: "first player style exceeds 255 bytes"}} =
               Styles.validate(:first, style)
    end

    test "second player, 256 bytes" do
      style = String.duplicate("A", 256)

      assert {:error, %ArgumentError{message: "second player style exceeds 255 bytes"}} =
               Styles.validate(:second, style)
    end

    test "far over limit" do
      style = String.duplicate("X", 10_000)

      assert {:error, %ArgumentError{message: "first player style exceeds 255 bytes"}} =
               Styles.validate(:first, style)
    end

    test "multi-byte UTF-8 exceeding limit" do
      # "é" is 2 bytes, 128 × 2 = 256 bytes > 255
      style = String.duplicate("é", 128)

      assert {:error, %ArgumentError{message: "second player style exceeds 255 bytes"}} =
               Styles.validate(:second, style)
    end
  end

  # ===========================================================================
  # Error message includes correct side
  # ===========================================================================

  describe "validate/2 error messages use correct side" do
    test "nil error for first" do
      {:error, %ArgumentError{message: msg}} = Styles.validate(:first, nil)
      assert msg =~ "first"
    end

    test "nil error for second" do
      {:error, %ArgumentError{message: msg}} = Styles.validate(:second, nil)
      assert msg =~ "second"
    end

    test "type error for first" do
      {:error, %ArgumentError{message: msg}} = Styles.validate(:first, 42)
      assert msg =~ "first"
    end

    test "type error for second" do
      {:error, %ArgumentError{message: msg}} = Styles.validate(:second, 42)
      assert msg =~ "second"
    end

    test "bytesize error for first" do
      {:error, %ArgumentError{message: msg}} = Styles.validate(:first, String.duplicate("A", 256))
      assert msg =~ "first"
    end

    test "bytesize error for second" do
      {:error, %ArgumentError{message: msg}} =
        Styles.validate(:second, String.duplicate("A", 256))

      assert msg =~ "second"
    end
  end

  # ===========================================================================
  # Validation order
  # ===========================================================================

  describe "validate/2 validation order" do
    test "nil checked before type" do
      # nil is not a string, but the nil-specific message takes priority
      assert {:error, %ArgumentError{message: "first player style must not be nil"}} =
               Styles.validate(:first, nil)
    end

    test "type checked before bytesize" do
      # an atom is not a string — type error, not bytesize error
      assert {:error, %ArgumentError{message: "second player style must be a String"}} =
               Styles.validate(:second, :chess)
    end
  end
end
