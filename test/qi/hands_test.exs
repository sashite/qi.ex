defmodule Qi.HandsTest do
  use ExUnit.Case, async: true

  alias Qi.Hands

  # ===========================================================================
  # Valid hands — counting
  # ===========================================================================

  describe "validate/1 with valid hands" do
    test "both empty" do
      assert {:ok, 0} = Hands.validate(%{first: [], second: []})
    end

    test "first has pieces, second empty" do
      assert {:ok, 2} = Hands.validate(%{first: [:P, :B], second: []})
    end

    test "second has pieces, first empty" do
      assert {:ok, 3} = Hands.validate(%{first: [], second: [:p, :p, :b]})
    end

    test "both have pieces" do
      assert {:ok, 5} = Hands.validate(%{first: [:P, :P, :B], second: [:p, :b]})
    end

    test "single piece in each hand" do
      assert {:ok, 2} = Hands.validate(%{first: [:R], second: [:r]})
    end

    test "duplicate pieces in same hand" do
      assert {:ok, 4} = Hands.validate(%{first: [:P, :P, :P, :P], second: []})
    end

    test "pieces as strings (EPIN-like)" do
      assert {:ok, 3} = Hands.validate(%{first: ["+P", "+P"], second: ["b"]})
    end

    test "pieces as tuples" do
      assert {:ok, 2} =
               Hands.validate(%{
                 first: [{:pawn, :first}],
                 second: [{:bishop, :second}]
               })
    end

    test "pieces as integers" do
      assert {:ok, 3} = Hands.validate(%{first: [1, 2], second: [3]})
    end

    test "mixed piece types in same hand" do
      assert {:ok, 3} = Hands.validate(%{first: [:P, "P", {:pawn, :first}], second: []})
    end

    test "large hands" do
      first = List.duplicate(:P, 100)
      second = List.duplicate(:p, 100)
      assert {:ok, 200} = Hands.validate(%{first: first, second: second})
    end
  end

  # ===========================================================================
  # Invalid hands — shape (not a map / wrong keys)
  # ===========================================================================

  describe "validate/1 rejects non-map input" do
    test "atom" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Hands.validate(:not_a_map)
    end

    test "string" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Hands.validate("not a map")
    end

    test "list" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Hands.validate([[], []])
    end

    test "nil" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Hands.validate(nil)
    end

    test "integer" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Hands.validate(42)
    end
  end

  describe "validate/1 rejects maps with wrong keys" do
    test "missing :second" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{first: []})
    end

    test "missing :first" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{second: []})
    end

    test "extra key" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{first: [], second: [], third: []})
    end

    test "completely wrong keys" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{a: [], b: []})
    end

    test "empty map" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{})
    end

    test "string keys instead of atoms" do
      assert {:error, %ArgumentError{message: "hands must have exactly keys :first and :second"}} =
               Hands.validate(%{"first" => [], "second" => []})
    end
  end

  # ===========================================================================
  # Invalid hands — values not lists
  # ===========================================================================

  describe "validate/1 rejects non-list hand values" do
    test "first hand is not a list" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: :not_list, second: []})
    end

    test "second hand is not a list" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: [], second: :not_list})
    end

    test "both hands are not lists" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: :a, second: :b})
    end

    test "hand value is a string" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: "P,B", second: []})
    end

    test "hand value is nil" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: nil, second: []})
    end

    test "hand value is an integer" do
      assert {:error, %ArgumentError{message: "each hand must be a list"}} =
               Hands.validate(%{first: [], second: 3})
    end
  end

  # ===========================================================================
  # Invalid hands — nil pieces
  # ===========================================================================

  describe "validate/1 rejects nil pieces" do
    test "nil in first hand" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [nil], second: []})
    end

    test "nil in second hand" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [], second: [nil]})
    end

    test "nil among other pieces in first hand" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [:P, nil, :B], second: []})
    end

    test "nil among other pieces in second hand" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [], second: [:p, nil]})
    end

    test "nil at end of first hand" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [:P, :B, nil], second: []})
    end

    test "nil in both hands (first detected first)" do
      assert {:error, %ArgumentError{message: "hand pieces must not be nil"}} =
               Hands.validate(%{first: [nil], second: [nil]})
    end
  end
end
