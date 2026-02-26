defmodule Qi.StylesTest do
  use ExUnit.Case, async: true

  alias Qi.Styles

  # ===========================================================================
  # Valid styles
  # ===========================================================================

  describe "validate/1 with valid styles" do
    test "strings (SIN-like)" do
      assert :ok = Styles.validate(%{first: "C", second: "c"})
    end

    test "single-character strings" do
      assert :ok = Styles.validate(%{first: "S", second: "s"})
    end

    test "atoms" do
      assert :ok = Styles.validate(%{first: :chess, second: :shogi})
    end

    test "same style for both sides" do
      assert :ok = Styles.validate(%{first: :chess, second: :chess})
    end

    test "tuples" do
      assert :ok =
               Styles.validate(%{
                 first: {:variant, "Chess960"},
                 second: {:variant, "Chess960"}
               })
    end

    test "integers" do
      assert :ok = Styles.validate(%{first: 1, second: 2})
    end

    test "booleans (non-nil terms)" do
      assert :ok = Styles.validate(%{first: true, second: false})
    end

    test "mixed types" do
      assert :ok = Styles.validate(%{first: "C", second: :shogi})
    end

    test "empty strings (non-nil)" do
      assert :ok = Styles.validate(%{first: "", second: ""})
    end

    test "empty lists (non-nil)" do
      assert :ok = Styles.validate(%{first: [], second: []})
    end
  end

  # ===========================================================================
  # Invalid styles — nil values
  # ===========================================================================

  describe "validate/1 rejects nil style values" do
    test "first is nil" do
      assert {:error, %ArgumentError{message: "first player style must not be nil"}} =
               Styles.validate(%{first: nil, second: "c"})
    end

    test "second is nil" do
      assert {:error, %ArgumentError{message: "second player style must not be nil"}} =
               Styles.validate(%{first: "C", second: nil})
    end

    test "both are nil (first detected first)" do
      assert {:error, %ArgumentError{message: "first player style must not be nil"}} =
               Styles.validate(%{first: nil, second: nil})
    end
  end

  # ===========================================================================
  # Invalid styles — wrong keys
  # ===========================================================================

  describe "validate/1 rejects maps with wrong keys" do
    test "missing :second" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{first: "C"})
    end

    test "missing :first" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{second: "c"})
    end

    test "extra key" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{first: "C", second: "c", third: "x"})
    end

    test "completely wrong keys" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{a: "C", b: "c"})
    end

    test "empty map" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{})
    end

    test "string keys instead of atoms" do
      assert {:error, %ArgumentError{message: "styles must have exactly keys :first and :second"}} =
               Styles.validate(%{"first" => "C", "second" => "c"})
    end
  end

  # ===========================================================================
  # Invalid styles — not a map
  # ===========================================================================

  describe "validate/1 rejects non-map input" do
    test "atom" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate(:not_a_map)
    end

    test "string" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate("not a map")
    end

    test "list" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate(["C", "c"])
    end

    test "nil" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate(nil)
    end

    test "integer" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate(42)
    end

    test "tuple" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Styles.validate({"C", "c"})
    end
  end
end
