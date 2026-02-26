defmodule Qi.BoardTest do
  use ExUnit.Case, async: true

  alias Qi.Board

  # ===========================================================================
  # Valid boards — dimensional detection and counting
  # ===========================================================================

  describe "validate/1 with valid 1D boards" do
    test "minimal: 1 square, 1 piece" do
      assert {:ok, {1, 1}} = Board.validate([:k])
    end

    test "minimal: 1 square, empty" do
      assert {:ok, {1, 0}} = Board.validate([nil])
    end

    test "all empty" do
      assert {:ok, {5, 0}} = Board.validate([nil, nil, nil, nil, nil])
    end

    test "all occupied" do
      assert {:ok, {3, 3}} = Board.validate([:a, :b, :c])
    end

    test "mixed occupied and empty" do
      assert {:ok, {4, 2}} = Board.validate([:k, nil, nil, :K])
    end

    test "pieces as strings" do
      assert {:ok, {3, 2}} = Board.validate(["K^", nil, "+p"])
    end

    test "pieces as tuples" do
      assert {:ok, {2, 2}} = Board.validate([{:king, :first}, {:king, :second}])
    end

    test "boundary: 255 squares" do
      assert {:ok, {255, 0}} = Board.validate(List.duplicate(nil, 255))
    end
  end

  describe "validate/1 with valid 2D boards" do
    test "minimal: 1×1" do
      assert {:ok, {1, 1}} = Board.validate([[:k]])
    end

    test "minimal: 1×1 empty" do
      assert {:ok, {1, 0}} = Board.validate([[nil]])
    end

    test "all empty" do
      assert {:ok, {4, 0}} = Board.validate([[nil, nil], [nil, nil]])
    end

    test "all occupied" do
      assert {:ok, {4, 4}} = Board.validate([[:a, :b], [:c, :d]])
    end

    test "chess-like 8×8" do
      board = [
        [:r, :n, :b, :q, :k, :b, :n, :r],
        [:p, :p, :p, :p, :p, :p, :p, :p],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [:P, :P, :P, :P, :P, :P, :P, :P],
        [:R, :N, :B, :Q, :K, :B, :N, :R]
      ]

      assert {:ok, {64, 32}} = Board.validate(board)
    end

    test "shogi-like 9×9" do
      board = [
        [:l, :n, :s, :g, :k, :g, :s, :n, :l],
        [nil, :r, nil, nil, nil, nil, nil, :b, nil],
        [:p, :p, :p, :p, :p, :p, :p, :p, :p],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [:P, :P, :P, :P, :P, :P, :P, :P, :P],
        [nil, :B, nil, nil, nil, nil, nil, :R, nil],
        [:L, :N, :S, :G, :K, :G, :S, :N, :L]
      ]

      assert {:ok, {81, 40}} = Board.validate(board)
    end

    test "xiangqi-like 10×9" do
      board = for _ <- 1..10, do: List.duplicate(nil, 9)
      assert {:ok, {90, 0}} = Board.validate(board)
    end

    test "boundary: 255 ranks × 1 file" do
      board = for _ <- 1..255, do: [nil]
      assert {:ok, {255, 0}} = Board.validate(board)
    end

    test "boundary: 1 rank × 255 files" do
      assert {:ok, {255, 0}} = Board.validate([List.duplicate(nil, 255)])
    end

    test "boundary: 255 ranks × 255 files" do
      board = for _ <- 1..255, do: List.duplicate(nil, 255)
      assert {:ok, {65_025, 0}} = Board.validate(board)
    end
  end

  describe "validate/1 with valid 3D boards" do
    test "minimal: 1×1×1" do
      assert {:ok, {1, 0}} = Board.validate([[[nil]]])
    end

    test "2×2×2 cube" do
      board = [
        [[:a, :b], [:c, :d]],
        [[:A, :B], [:C, :D]]
      ]

      assert {:ok, {8, 8}} = Board.validate(board)
    end

    test "2 layers × 2 ranks × 3 files with mixed occupancy" do
      board = [
        [[:a, nil, :b], [nil, nil, nil]],
        [[nil, :c, nil], [:d, nil, :e]]
      ]

      assert {:ok, {12, 5}} = Board.validate(board)
    end

    test "3 layers × 2 ranks × 2 files" do
      board = [
        [[:a, :b], [:c, :d]],
        [[:e, :f], [:g, :h]],
        [[:i, :j], [:k, :l]]
      ]

      assert {:ok, {12, 12}} = Board.validate(board)
    end

    test "Raumschach-like 5×5×5" do
      board = for _ <- 1..5, do: for(_ <- 1..5, do: List.duplicate(nil, 5))
      assert {:ok, {125, 0}} = Board.validate(board)
    end

    test "boundary: 255 layers × 1 rank × 1 file" do
      board = for _ <- 1..255, do: [[nil]]
      assert {:ok, {255, 0}} = Board.validate(board)
    end
  end

  # ===========================================================================
  # Invalid boards — type checks
  # ===========================================================================

  describe "validate/1 rejects non-list input" do
    test "atom" do
      assert {:error, %ArgumentError{message: "board must be a list"}} = Board.validate(:atom)
    end

    test "integer" do
      assert {:error, %ArgumentError{message: "board must be a list"}} = Board.validate(42)
    end

    test "string" do
      assert {:error, %ArgumentError{message: "board must be a list"}} =
               Board.validate("not a board")
    end

    test "map" do
      assert {:error, %ArgumentError{message: "board must be a list"}} = Board.validate(%{a: 1})
    end

    test "nil" do
      assert {:error, %ArgumentError{message: "board must be a list"}} = Board.validate(nil)
    end
  end

  describe "validate/1 rejects empty board" do
    test "empty list" do
      assert {:error, %ArgumentError{message: "board must not be empty"}} = Board.validate([])
    end
  end

  # ===========================================================================
  # Invalid boards — dimension limits
  # ===========================================================================

  describe "validate/1 rejects boards exceeding 3 dimensions" do
    test "4D board" do
      assert {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 4)"}} =
               Board.validate([[[[:a]]]])
    end

    test "5D board" do
      assert {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 5)"}} =
               Board.validate([[[[[:a]]]]])
    end
  end

  describe "validate/1 rejects dimension sizes exceeding 255" do
    test "1D: 256 squares" do
      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate(List.duplicate(nil, 256))
    end

    test "2D: 256 ranks" do
      board = for _ <- 1..256, do: [nil]

      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate(board)
    end

    test "2D: 256 files per rank" do
      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate([List.duplicate(nil, 256)])
    end

    test "3D: 256 layers" do
      board = for _ <- 1..256, do: [[nil]]

      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate(board)
    end
  end

  # ===========================================================================
  # Invalid boards — rectangularity
  # ===========================================================================

  describe "validate/1 rejects non-rectangular boards" do
    test "2D: jagged ranks" do
      assert {:error,
              %ArgumentError{
                message: "non-rectangular board: expected 2 elements, got 1"
              }} = Board.validate([[:a, :b], [:c]])
    end

    test "3D: jagged ranks within a layer" do
      board = [
        [[:a, :b], [:c]],
        [[:d, :e], [:f, :g]]
      ]

      assert {:error,
              %ArgumentError{
                message: "non-rectangular board: expected 2 elements, got 1"
              }} = Board.validate(board)
    end

    test "3D: different rank widths across layers" do
      board = [
        [[:a, :b], [:c, :d]],
        [[:e, :f, :g], [:h, :i, :j]]
      ]

      assert {:error,
              %ArgumentError{
                message: "non-rectangular board: expected 2 elements, got 3"
              }} = Board.validate(board)
    end

    test "3D: different rank counts across layers" do
      board = [
        [[:a, :b], [:c, :d]],
        [[:e, :f]]
      ]

      assert {:error,
              %ArgumentError{
                message: "non-rectangular board: expected 2 elements, got 1"
              }} = Board.validate(board)
    end
  end

  # ===========================================================================
  # Invalid boards — structural consistency
  # ===========================================================================

  describe "validate/1 rejects inconsistent board structures" do
    test "mixed lists and non-lists at same level (2D)" do
      assert {:error,
              %ArgumentError{
                message: "inconsistent board structure: mixed lists and non-lists at same level"
              }} = Board.validate([[:a], :b])
    end

    test "mixed lists and non-lists at same level (3D)" do
      board = [
        [[:a, :b], [:c, :d]],
        :not_a_layer
      ]

      assert {:error,
              %ArgumentError{
                message: "inconsistent board structure: mixed lists and non-lists at same level"
              }} = Board.validate(board)
    end

    test "list nested inside a 1D board" do
      assert {:error,
              %ArgumentError{
                message: "inconsistent board structure: expected flat squares at this level"
              }} = Board.validate([:a, [:b]])
    end

    test "list nested at end of a 1D board" do
      assert {:error,
              %ArgumentError{
                message: "inconsistent board structure: expected flat squares at this level"
              }} = Board.validate([:a, :b, [:c]])
    end
  end
end
