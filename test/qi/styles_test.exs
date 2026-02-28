defmodule Qi.StylesTest do
  use ExUnit.Case, async: true

  alias Qi.Styles

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
  end
end
