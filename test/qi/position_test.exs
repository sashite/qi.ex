defmodule Qi.PositionTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # Valid positions — realistic game scenarios
  # ===========================================================================

  describe "new/4 with chess positions" do
    test "starting position" do
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

      assert {:ok, pos} =
               Qi.new(board, %{first: [], second: []}, %{first: "C", second: "c"}, :first)

      assert pos.turn == :first
    end

    test "mid-game with captures in hand (Crazyhouse-like)" do
      board = [
        [nil, nil, nil, nil, :k, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :K, nil, nil, nil]
      ]

      hands = %{first: [:P, :N, :B], second: [:p, :r]}

      assert {:ok, pos} = Qi.new(board, hands, %{first: "C", second: "c"}, :second)
      assert pos.hands.first == [:P, :N, :B]
      assert pos.hands.second == [:p, :r]
      assert pos.turn == :second
    end
  end

  describe "new/4 with shogi positions" do
    test "starting position" do
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

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "S", second: "s"}, :first)
    end

    test "mid-game with pieces in hand" do
      board = [
        [nil, nil, nil, :g, :k, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, :K, nil, nil, nil, nil]
      ]

      hands = %{first: [:P, :P, :L, :N, :S, :G, :B, :R], second: [:p, :p, :p]}

      assert {:ok, pos} = Qi.new(board, hands, %{first: "S", second: "s"}, :first)
      assert length(pos.hands.first) == 8
      assert length(pos.hands.second) == 3
    end
  end

  describe "new/4 with other game types" do
    test "xiangqi-like 10×9 empty board" do
      board = for _ <- 1..10, do: List.duplicate(nil, 9)

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "X", second: "x"}, :first)
    end

    test "3D board (Raumschach-like)" do
      board = for _ <- 1..5, do: for(_ <- 1..5, do: List.duplicate(nil, 5))

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "R", second: "r"}, :first)
    end

    test "1D board" do
      assert {:ok, _} =
               Qi.new(
                 [:k, nil, nil, nil, :K],
                 %{first: [], second: []},
                 %{first: "C", second: "c"},
                 :first
               )
    end

    test "placement game: empty board with pieces in hands" do
      board = for _ <- 1..3, do: List.duplicate(nil, 3)

      assert {:ok, pos} =
               Qi.new(
                 board,
                 %{first: [:a, :b, :c], second: [:x, :y, :z]},
                 %{first: "G", second: "g"},
                 :first
               )

      assert pos.board == [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
      assert length(pos.hands.first) == 3
    end
  end

  # ===========================================================================
  # Format agnosticism — piece and style types
  # ===========================================================================

  describe "new/4 accepts any non-nil piece type" do
    test "atoms" do
      assert {:ok, _} =
               Qi.new(
                 [[:K, nil], [nil, :k]],
                 %{first: [], second: []},
                 %{first: "C", second: "c"},
                 :first
               )
    end

    test "strings (EPIN-like)" do
      assert {:ok, pos} =
               Qi.new(
                 [["K^", nil], [nil, "+p"]],
                 %{first: [], second: []},
                 %{first: "C", second: "c"},
                 :first
               )

      assert hd(hd(pos.board)) == "K^"
    end

    test "tuples" do
      board = [[{:king, :first, true}, nil], [nil, {:king, :second, true}]]

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: :chess, second: :chess}, :first)
    end

    test "integers" do
      assert {:ok, _} =
               Qi.new(
                 [[1, nil], [nil, 2]],
                 %{first: [], second: []},
                 %{first: "C", second: "c"},
                 :first
               )
    end

    test "mixed types on same board" do
      board = [[:K, "p", {:rook, :second}], [nil, 42, nil]]

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "mixed types in hands" do
      assert {:ok, _} =
               Qi.new(
                 [[nil, nil], [nil, nil]],
                 %{first: [:P, "P"], second: [{:pawn, :second}]},
                 %{first: "C", second: "c"},
                 :first
               )
    end
  end

  describe "new/4 accepts any non-nil style type" do
    test "strings" do
      assert {:ok, pos} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

      assert pos.styles == %{first: "C", second: "c"}
    end

    test "atoms" do
      assert {:ok, pos} =
               Qi.new([nil], %{first: [], second: []}, %{first: :chess, second: :shogi}, :first)

      assert pos.styles == %{first: :chess, second: :shogi}
    end

    test "tuples" do
      styles = %{first: {:variant, "Chess960"}, second: {:variant, "Standard"}}
      assert {:ok, _} = Qi.new([nil], %{first: [], second: []}, styles, :first)
    end

    test "same style both sides" do
      assert {:ok, _} =
               Qi.new([nil], %{first: [], second: []}, %{first: :chess, second: :chess}, :first)
    end
  end

  # ===========================================================================
  # Turn validation (Position's own logic)
  # ===========================================================================

  describe "new/4 with valid turn" do
    test ":first" do
      assert {:ok, pos} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

      assert pos.turn == :first
    end

    test ":second" do
      assert {:ok, pos} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :second)

      assert pos.turn == :second
    end
  end

  describe "new/4 rejects invalid turn" do
    test "string instead of atom" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, "first")
    end

    test "wrong atom" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :third)
    end

    test "nil" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, nil)
    end

    test "integer" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, 1)
    end

    test "boolean" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, true)
    end
  end

  # ===========================================================================
  # Cardinality validation (Position's own logic)
  # ===========================================================================

  describe "new/4 cardinality — valid edge cases" do
    test "p == n: board fully occupied, no hand pieces" do
      board = [[:a, :b], [:c, :d]]

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "p == n: board + hands at exact limit" do
      # 4 squares, 2 on board + 2 in hands = 4 total
      board = [[:a, nil], [nil, :b]]
      hands = %{first: [:c], second: [:d]}
      assert {:ok, _} = Qi.new(board, hands, %{first: "C", second: "c"}, :first)
    end

    test "p == 0: empty board, no hand pieces" do
      board = for _ <- 1..8, do: List.duplicate(nil, 8)

      assert {:ok, _} =
               Qi.new(board, %{first: [], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "p == 1: single piece on board" do
      assert {:ok, _} = Qi.new([:k], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "p == 1: single piece in hand" do
      assert {:ok, _} =
               Qi.new([nil], %{first: [:k], second: []}, %{first: "C", second: "c"}, :first)
    end
  end

  describe "new/4 rejects cardinality violations" do
    test "1 square, 1 on board + 1 in hand = 2 > 1" do
      assert {:error,
              %ArgumentError{
                message: "too many pieces for board size (2 pieces, 1 squares)"
              }} = Qi.new([:k], %{first: [:P], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "2 squares, 1 on board + 2 in hands = 3 > 2" do
      assert {:error,
              %ArgumentError{
                message: "too many pieces for board size (3 pieces, 2 squares)"
              }} =
               Qi.new(
                 [nil, :k],
                 %{first: [:P, :Q], second: []},
                 %{first: "C", second: "c"},
                 :first
               )
    end

    test "4 squares, 4 on board + 1 in hand = 5 > 4" do
      board = [[:a, :b], [:c, :d]]

      assert {:error,
              %ArgumentError{
                message: "too many pieces for board size (5 pieces, 4 squares)"
              }} = Qi.new(board, %{first: [:e], second: []}, %{first: "C", second: "c"}, :first)
    end

    test "violation from hand pieces only (empty board)" do
      assert {:error,
              %ArgumentError{
                message: "too many pieces for board size (2 pieces, 1 squares)"
              }} = Qi.new([nil], %{first: [:P], second: [:p]}, %{first: "C", second: "c"}, :first)
    end
  end

  # ===========================================================================
  # Delegation smoke tests — one per sub-module error category
  # (detailed coverage is in board_test, hands_test, styles_test)
  # ===========================================================================

  describe "new/4 delegates board validation" do
    test "rejects invalid board" do
      assert {:error, %ArgumentError{message: "board must be a list"}} =
               Qi.new(:not_a_board, %{first: [], second: []}, %{first: "C", second: "c"}, :first)
    end
  end

  describe "new/4 delegates hands validation" do
    test "rejects invalid hands" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Qi.new([nil], :not_hands, %{first: "C", second: "c"}, :first)
    end
  end

  describe "new/4 delegates styles validation" do
    test "rejects invalid styles" do
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Qi.new([nil], %{first: [], second: []}, :not_styles, :first)
    end
  end

  # ===========================================================================
  # Validation order — turn is checked first (cheapest)
  # ===========================================================================

  describe "new/4 validation order" do
    test "turn error takes priority over board error" do
      assert {:error, %ArgumentError{message: "turn must be :first or :second"}} =
               Qi.new(:bad_board, :bad_hands, :bad_styles, :bad_turn)
    end

    test "board error takes priority over hands error" do
      assert {:error, %ArgumentError{message: "board must be a list"}} =
               Qi.new(:bad_board, :bad_hands, :bad_styles, :first)
    end

    test "hands error takes priority over styles error" do
      assert {:error, %ArgumentError{message: "hands must be a map with keys :first and :second"}} =
               Qi.new([nil], :bad_hands, :bad_styles, :first)
    end

    test "styles error takes priority over cardinality" do
      # 1 square with 1 piece on board + 1 in hand would violate cardinality,
      # but styles error should be reported first.
      assert {:error,
              %ArgumentError{message: "styles must be a map with keys :first and :second"}} =
               Qi.new([:k], %{first: [:P], second: []}, :bad_styles, :first)
    end
  end

  # ===========================================================================
  # Bang variant
  # ===========================================================================

  describe "new!/4" do
    test "returns position on valid input" do
      pos = Qi.new!([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
      assert %Qi.Position{} = pos
    end

    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, "board must not be empty", fn ->
        Qi.new!([], %{first: [], second: []}, %{first: "C", second: "c"}, :first)
      end
    end

    test "raises with correct message for turn error" do
      assert_raise ArgumentError, "turn must be :first or :second", fn ->
        Qi.new!([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :third)
      end
    end

    test "raises with correct message for cardinality error" do
      assert_raise ArgumentError, ~r/too many pieces/, fn ->
        Qi.new!([:k], %{first: [:P], second: []}, %{first: "C", second: "c"}, :first)
      end
    end
  end

  # ===========================================================================
  # Struct field access
  # ===========================================================================

  describe "field accessors" do
    setup do
      board = [[:r, nil, nil], [nil, nil, nil], [nil, nil, :R]]
      hands = %{first: [:P, :B], second: [:p]}
      styles = %{first: "C", second: "c"}
      {:ok, pos} = Qi.new(board, hands, styles, :second)
      %{pos: pos}
    end

    test "board", %{pos: pos} do
      assert pos.board == [[:r, nil, nil], [nil, nil, nil], [nil, nil, :R]]
    end

    test "hands", %{pos: pos} do
      assert pos.hands == %{first: [:P, :B], second: [:p]}
    end

    test "styles", %{pos: pos} do
      assert pos.styles == %{first: "C", second: "c"}
    end

    test "turn", %{pos: pos} do
      assert pos.turn == :second
    end
  end

  # ===========================================================================
  # Struct type
  # ===========================================================================

  describe "struct type" do
    test "result is a Qi.Position struct" do
      {:ok, pos} = Qi.new([nil], %{first: [], second: []}, %{first: "C", second: "c"}, :first)

      assert %Qi.Position{} = pos
      assert is_map(pos)
      assert pos.__struct__ == Qi.Position
    end
  end
end
