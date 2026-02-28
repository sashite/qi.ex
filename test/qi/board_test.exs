defmodule Qi.BoardTest do
  use ExUnit.Case, async: true

  alias Qi.Board

  # ===========================================================================
  # Constants
  # ===========================================================================

  describe "max_dimensions/0" do
    test "returns 3" do
      assert Board.max_dimensions() == 3
    end
  end

  describe "max_dimension_size/0" do
    test "returns 255" do
      assert Board.max_dimension_size() == 255
    end
  end

  # ===========================================================================
  # validate_shape/1 — valid shapes
  # ===========================================================================

  describe "validate_shape/1 with valid 1D shapes" do
    test "minimal: 1 square" do
      assert {:ok, 1} = Board.validate_shape([1])
    end

    test "8 squares" do
      assert {:ok, 8} = Board.validate_shape([8])
    end

    test "boundary: 255 squares" do
      assert {:ok, 255} = Board.validate_shape([255])
    end
  end

  describe "validate_shape/1 with valid 2D shapes" do
    test "minimal: 1×1" do
      assert {:ok, 1} = Board.validate_shape([1, 1])
    end

    test "chess: 8×8" do
      assert {:ok, 64} = Board.validate_shape([8, 8])
    end

    test "shogi: 9×9" do
      assert {:ok, 81} = Board.validate_shape([9, 9])
    end

    test "xiangqi: 10×9" do
      assert {:ok, 90} = Board.validate_shape([10, 9])
    end

    test "boundary: 255×255" do
      assert {:ok, 65_025} = Board.validate_shape([255, 255])
    end

    test "asymmetric: 1×255" do
      assert {:ok, 255} = Board.validate_shape([1, 255])
    end

    test "asymmetric: 255×1" do
      assert {:ok, 255} = Board.validate_shape([255, 1])
    end
  end

  describe "validate_shape/1 with valid 3D shapes" do
    test "minimal: 1×1×1" do
      assert {:ok, 1} = Board.validate_shape([1, 1, 1])
    end

    test "Raumschach: 5×5×5" do
      assert {:ok, 125} = Board.validate_shape([5, 5, 5])
    end

    test "boundary: 255×255×255" do
      assert {:ok, 16_581_375} = Board.validate_shape([255, 255, 255])
    end
  end

  # ===========================================================================
  # validate_shape/1 — invalid shapes
  # ===========================================================================

  describe "validate_shape/1 rejects empty shape" do
    test "empty list" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape([])
    end
  end

  describe "validate_shape/1 rejects non-list input" do
    test "nil" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape(nil)
    end

    test "integer" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape(8)
    end

    test "atom" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape(:chess)
    end

    test "string" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape("8x8")
    end

    test "tuple" do
      assert {:error, %ArgumentError{message: "at least one dimension is required"}} =
               Board.validate_shape({8, 8})
    end
  end

  describe "validate_shape/1 rejects too many dimensions" do
    test "4D" do
      assert {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 4)"}} =
               Board.validate_shape([2, 2, 2, 2])
    end

    test "5D" do
      assert {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 5)"}} =
               Board.validate_shape([1, 1, 1, 1, 1])
    end
  end

  describe "validate_shape/1 rejects non-integer dimension sizes" do
    test "float" do
      assert {:error, %ArgumentError{message: "dimension size must be an integer, got 8.0"}} =
               Board.validate_shape([8.0])
    end

    test "string" do
      assert {:error, %ArgumentError{message: ~s(dimension size must be an integer, got "8")}} =
               Board.validate_shape(["8"])
    end

    test "atom" do
      assert {:error, %ArgumentError{message: "dimension size must be an integer, got :eight"}} =
               Board.validate_shape([:eight])
    end

    test "nil" do
      assert {:error, %ArgumentError{message: "dimension size must be an integer, got nil"}} =
               Board.validate_shape([nil])
    end

    test "non-integer in second position" do
      assert {:error, %ArgumentError{message: "dimension size must be an integer, got :bad"}} =
               Board.validate_shape([8, :bad])
    end
  end

  describe "validate_shape/1 rejects dimension sizes below 1" do
    test "zero" do
      assert {:error, %ArgumentError{message: "dimension size must be at least 1, got 0"}} =
               Board.validate_shape([0])
    end

    test "negative" do
      assert {:error, %ArgumentError{message: "dimension size must be at least 1, got -1"}} =
               Board.validate_shape([-1])
    end

    test "zero in second dimension" do
      assert {:error, %ArgumentError{message: "dimension size must be at least 1, got 0"}} =
               Board.validate_shape([8, 0])
    end
  end

  describe "validate_shape/1 rejects dimension sizes above 255" do
    test "256 in 1D" do
      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate_shape([256])
    end

    test "256 in second dimension" do
      assert {:error, %ArgumentError{message: "dimension size 256 exceeds maximum of 255"}} =
               Board.validate_shape([8, 256])
    end

    test "1000" do
      assert {:error, %ArgumentError{message: "dimension size 1000 exceeds maximum of 255"}} =
               Board.validate_shape([1000])
    end
  end

  describe "validate_shape/1 validation order" do
    test "dimension count checked before dimension values" do
      # 4D with invalid sizes — dimension count error should come first
      assert {:error, %ArgumentError{message: "board exceeds 3 dimensions (got 4)"}} =
               Board.validate_shape([0, 0, 0, 0])
    end

    test "first invalid dimension reported" do
      assert {:error, %ArgumentError{message: "dimension size must be at least 1, got 0"}} =
               Board.validate_shape([0, 256])
    end
  end

  # ===========================================================================
  # new/1
  # ===========================================================================

  describe "new/1" do
    test "creates empty board of size 1" do
      assert Board.new(1) == {nil}
    end

    test "creates empty board of size 4" do
      board = Board.new(4)
      assert board == {nil, nil, nil, nil}
      assert tuple_size(board) == 4
    end

    test "creates empty board of size 64 (chess)" do
      board = Board.new(64)
      assert tuple_size(board) == 64
      assert elem(board, 0) == nil
      assert elem(board, 63) == nil
    end

    test "all elements are nil" do
      board = Board.new(10)

      for i <- 0..9 do
        assert elem(board, i) == nil
      end
    end
  end

  # ===========================================================================
  # diff/2 — valid diffs
  # ===========================================================================

  describe "diff/2 with valid changes" do
    test "place a single piece" do
      board = Board.new(4)
      assert {:ok, new_board, 1} = Board.diff(board, [{0, "K"}])
      assert elem(new_board, 0) == "K"
    end

    test "place multiple pieces" do
      board = Board.new(4)
      assert {:ok, new_board, 2} = Board.diff(board, [{0, "K"}, {3, "k"}])
      assert elem(new_board, 0) == "K"
      assert elem(new_board, 1) == nil
      assert elem(new_board, 2) == nil
      assert elem(new_board, 3) == "k"
    end

    test "remove a piece" do
      {:ok, board, 1} = Board.diff(Board.new(4), [{0, "K"}])
      assert {:ok, new_board, -1} = Board.diff(board, [{0, nil}])
      assert elem(new_board, 0) == nil
    end

    test "move a piece (remove + place)" do
      {:ok, board, 1} = Board.diff(Board.new(4), [{0, "K"}])
      assert {:ok, new_board, 0} = Board.diff(board, [{0, nil}, {3, "K"}])
      assert elem(new_board, 0) == nil
      assert elem(new_board, 3) == "K"
    end

    test "replace a piece (overwrite)" do
      {:ok, board, 1} = Board.diff(Board.new(4), [{0, "K"}])
      assert {:ok, new_board, 0} = Board.diff(board, [{0, "Q"}])
      assert elem(new_board, 0) == "Q"
    end

    test "clear an already empty square (no-op delta)" do
      board = Board.new(4)
      assert {:ok, ^board, 0} = Board.diff(board, [{0, nil}])
    end

    test "empty changes list" do
      board = Board.new(4)
      assert {:ok, ^board, 0} = Board.diff(board, [])
    end

    test "does not modify original board" do
      board = Board.new(4)
      {:ok, _new_board, 1} = Board.diff(board, [{0, "K"}])
      assert elem(board, 0) == nil
    end

    test "boundary: last valid index" do
      board = Board.new(4)
      assert {:ok, new_board, 1} = Board.diff(board, [{3, "k"}])
      assert elem(new_board, 3) == "k"
    end

    test "boundary: first valid index" do
      board = Board.new(4)
      assert {:ok, new_board, 1} = Board.diff(board, [{0, "K"}])
      assert elem(new_board, 0) == "K"
    end

    test "piece with special characters" do
      board = Board.new(2)
      assert {:ok, new_board, 2} = Board.diff(board, [{0, "+P"}, {1, "C:K^"}])
      assert elem(new_board, 0) == "+P"
      assert elem(new_board, 1) == "C:K^"
    end

    test "chess starting position (32 pieces on 64 squares)" do
      board = Board.new(64)

      back_rank_w = [
        {56, "R"},
        {57, "N"},
        {58, "B"},
        {59, "Q"},
        {60, "K"},
        {61, "B"},
        {62, "N"},
        {63, "R"}
      ]

      pawns_w = for f <- 48..55, do: {f, "P"}

      back_rank_b = [
        {0, "r"},
        {1, "n"},
        {2, "b"},
        {3, "q"},
        {4, "k"},
        {5, "b"},
        {6, "n"},
        {7, "r"}
      ]

      pawns_b = for f <- 8..15, do: {f, "p"}

      {:ok, new_board, 32} = Board.diff(board, back_rank_w ++ pawns_w ++ back_rank_b ++ pawns_b)
      assert elem(new_board, 60) == "K"
      assert elem(new_board, 4) == "k"
      assert elem(new_board, 32) == nil
    end
  end

  # ===========================================================================
  # diff/2 — invalid diffs
  # ===========================================================================

  describe "diff/2 rejects invalid flat indices" do
    test "index out of range (positive)" do
      assert {:error, %ArgumentError{message: "invalid flat index: 4 (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{4, "K"}])
    end

    test "negative index" do
      assert {:error, %ArgumentError{message: "invalid flat index: -1 (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{-1, "K"}])
    end

    test "non-integer index (string)" do
      assert {:error, %ArgumentError{message: "invalid flat index: \"a1\" (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{"a1", "K"}])
    end

    test "non-integer index (atom)" do
      assert {:error, %ArgumentError{message: "invalid flat index: :zero (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{:zero, "K"}])
    end

    test "non-integer index (float)" do
      assert {:error, %ArgumentError{message: "invalid flat index: 0.0 (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{0.0, "K"}])
    end

    test "valid change before invalid index" do
      assert {:error, %ArgumentError{message: "invalid flat index: 10 (board has 4 squares)"}} =
               Board.diff(Board.new(4), [{0, "K"}, {10, "k"}])
    end
  end

  describe "diff/2 rejects non-string pieces" do
    test "atom piece" do
      assert {:error, %ArgumentError{message: "piece must be a string or nil, got :K"}} =
               Board.diff(Board.new(4), [{0, :K}])
    end

    test "integer piece" do
      assert {:error, %ArgumentError{message: "piece must be a string or nil, got 1"}} =
               Board.diff(Board.new(4), [{0, 1}])
    end

    test "tuple piece" do
      assert {:error,
              %ArgumentError{
                message: "piece must be a string or nil, got {:king, :first}"
              }} = Board.diff(Board.new(4), [{0, {:king, :first}}])
    end

    test "boolean piece" do
      assert {:error, %ArgumentError{message: "piece must be a string or nil, got true"}} =
               Board.diff(Board.new(4), [{0, true}])
    end
  end

  # ===========================================================================
  # diff/2 — delta tracking
  # ===========================================================================

  describe "diff/2 piece delta tracking" do
    test "nil → string = +1" do
      assert {:ok, _, 1} = Board.diff(Board.new(2), [{0, "K"}])
    end

    test "string → nil = -1" do
      {:ok, board, _} = Board.diff(Board.new(2), [{0, "K"}])
      assert {:ok, _, -1} = Board.diff(board, [{0, nil}])
    end

    test "string → string = 0" do
      {:ok, board, _} = Board.diff(Board.new(2), [{0, "K"}])
      assert {:ok, _, 0} = Board.diff(board, [{0, "Q"}])
    end

    test "nil → nil = 0" do
      assert {:ok, _, 0} = Board.diff(Board.new(2), [{0, nil}])
    end

    test "multiple changes accumulate" do
      board = Board.new(4)
      assert {:ok, _, 3} = Board.diff(board, [{0, "a"}, {1, "b"}, {2, "c"}])
    end

    test "mixed add and remove" do
      {:ok, board, _} = Board.diff(Board.new(4), [{0, "K"}, {1, "Q"}])
      assert {:ok, _, -1} = Board.diff(board, [{0, nil}, {2, "R"}, {1, nil}])
    end
  end

  # ===========================================================================
  # piece_count/1
  # ===========================================================================

  describe "piece_count/1" do
    test "empty board" do
      assert Board.piece_count(Board.new(4)) == 0
    end

    test "fully occupied board" do
      {:ok, board, _} = Board.diff(Board.new(2), [{0, "a"}, {1, "b"}])
      assert Board.piece_count(board) == 2
    end

    test "partially occupied" do
      {:ok, board, _} = Board.diff(Board.new(4), [{1, "K"}, {3, "k"}])
      assert Board.piece_count(board) == 2
    end

    test "single square board, occupied" do
      {:ok, board, _} = Board.diff(Board.new(1), [{0, "K"}])
      assert Board.piece_count(board) == 1
    end

    test "single square board, empty" do
      assert Board.piece_count(Board.new(1)) == 0
    end
  end

  # ===========================================================================
  # to_nested/2
  # ===========================================================================

  describe "to_nested/2 with 1D shapes" do
    test "flat list returned" do
      board = Board.new(3)
      assert Board.to_nested(board, [3]) == [nil, nil, nil]
    end

    test "with pieces" do
      {:ok, board, _} = Board.diff(Board.new(3), [{0, "a"}, {2, "c"}])
      assert Board.to_nested(board, [3]) == ["a", nil, "c"]
    end

    test "single element" do
      assert Board.to_nested(Board.new(1), [1]) == [nil]
    end
  end

  describe "to_nested/2 with 2D shapes" do
    test "2×2" do
      {:ok, board, _} = Board.diff(Board.new(4), [{0, "a"}, {3, "d"}])
      assert Board.to_nested(board, [2, 2]) == [["a", nil], [nil, "d"]]
    end

    test "2×3" do
      {:ok, board, _} = Board.diff(Board.new(6), [{0, "a"}, {5, "f"}])
      assert Board.to_nested(board, [2, 3]) == [["a", nil, nil], [nil, nil, "f"]]
    end

    test "3×3 empty" do
      board = Board.new(9)
      expected = [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
      assert Board.to_nested(board, [3, 3]) == expected
    end

    test "1×4" do
      board = Board.new(4)
      assert Board.to_nested(board, [1, 4]) == [[nil, nil, nil, nil]]
    end

    test "4×1" do
      board = Board.new(4)
      assert Board.to_nested(board, [4, 1]) == [[nil], [nil], [nil], [nil]]
    end
  end

  describe "to_nested/2 with 3D shapes" do
    test "2×2×2" do
      {:ok, board, _} = Board.diff(Board.new(8), [{0, "a"}, {7, "h"}])

      assert Board.to_nested(board, [2, 2, 2]) == [
               [["a", nil], [nil, nil]],
               [[nil, nil], [nil, "h"]]
             ]
    end

    test "2×2×2 empty" do
      board = Board.new(8)

      assert Board.to_nested(board, [2, 2, 2]) == [
               [[nil, nil], [nil, nil]],
               [[nil, nil], [nil, nil]]
             ]
    end

    test "1×1×1" do
      board = Board.new(1)
      assert Board.to_nested(board, [1, 1, 1]) == [[[nil]]]
    end

    test "2×3×4" do
      board = Board.new(24)
      nested = Board.to_nested(board, [2, 3, 4])
      # 2 layers, 3 ranks each, 4 files each
      assert length(nested) == 2
      assert length(hd(nested)) == 3
      assert length(hd(hd(nested))) == 4
    end
  end
end
