defmodule QiTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # Constants
  # ===========================================================================

  describe "max_dimensions/0" do
    test "returns 3" do
      assert Qi.max_dimensions() == 3
    end
  end

  describe "max_dimension_size/0" do
    test "returns 255" do
      assert Qi.max_dimension_size() == 255
    end
  end

  describe "max_square_count/0" do
    test "returns 65025" do
      assert Qi.max_square_count() == 65_025
    end
  end

  describe "max_piece_bytesize/0" do
    test "returns 255" do
      assert Qi.max_piece_bytesize() == 255
    end
  end

  describe "max_style_bytesize/0" do
    test "returns 255" do
      assert Qi.max_style_bytesize() == 255
    end
  end

  # ===========================================================================
  # new/2 — valid constructions
  # ===========================================================================

  describe "new/2 with valid inputs" do
    test "1D board" do
      pos = Qi.new([8], first_player_style: "C", second_player_style: "c")
      assert pos.shape == [8]
      assert tuple_size(pos.board) == 8
    end

    test "2D board (chess)" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert pos.shape == [8, 8]
      assert tuple_size(pos.board) == 64
    end

    test "2D board (shogi)" do
      pos = Qi.new([9, 9], first_player_style: "S", second_player_style: "s")
      assert pos.shape == [9, 9]
      assert tuple_size(pos.board) == 81
    end

    test "2D board (xiangqi)" do
      pos = Qi.new([10, 9], first_player_style: "X", second_player_style: "x")
      assert pos.shape == [10, 9]
      assert tuple_size(pos.board) == 90
    end

    test "3D board (Raumschach)" do
      pos = Qi.new([5, 5, 5], first_player_style: "R", second_player_style: "r")
      assert pos.shape == [5, 5, 5]
      assert tuple_size(pos.board) == 125
    end

    test "minimal board (1 square)" do
      pos = Qi.new([1], first_player_style: "C", second_player_style: "c")
      assert tuple_size(pos.board) == 1
    end

    test "board starts empty" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")

      for i <- 0..3 do
        assert elem(pos.board, i) == nil
      end
    end

    test "hands start empty" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert pos.first_player_hand == %{}
      assert pos.second_player_hand == %{}
    end

    test "turn starts as :first" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert pos.turn == :first
    end

    test "styles are stored" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert pos.first_player_style == "C"
      assert pos.second_player_style == "c"
    end

    test "same style for both players" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "C")
      assert pos.first_player_style == "C"
      assert pos.second_player_style == "C"
    end

    test "result is a Qi struct" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert %Qi{} = pos
    end

    test "2D boundary: 255×255 = 65025 squares" do
      pos = Qi.new([255, 255], first_player_style: "C", second_player_style: "c")
      assert tuple_size(pos.board) == 65_025
    end

    test "3D boundary: 255×255×1 = 65025 squares" do
      pos = Qi.new([255, 255, 1], first_player_style: "C", second_player_style: "c")
      assert tuple_size(pos.board) == 65_025
    end

    test "style at exactly 255 bytes" do
      style = String.duplicate("A", 255)
      pos = Qi.new([1], first_player_style: style, second_player_style: style)
      assert pos.first_player_style == style
      assert pos.second_player_style == style
    end

    test "multi-byte UTF-8 style within limit" do
      # "é" is 2 bytes, 127 × 2 = 254 bytes ≤ 255
      style = String.duplicate("é", 127)
      pos = Qi.new([1], first_player_style: style, second_player_style: "c")
      assert pos.first_player_style == style
    end

    test "empty string styles" do
      pos = Qi.new([1], first_player_style: "", second_player_style: "")
      assert pos.first_player_style == ""
      assert pos.second_player_style == ""
    end
  end

  # ===========================================================================
  # new/2 — construction errors (shape)
  # ===========================================================================

  describe "new/2 rejects invalid shapes" do
    test "empty shape" do
      assert_raise ArgumentError, "at least one dimension is required", fn ->
        Qi.new([], first_player_style: "C", second_player_style: "c")
      end
    end

    test "too many dimensions" do
      assert_raise ArgumentError, "board exceeds 3 dimensions (got 4)", fn ->
        Qi.new([2, 2, 2, 2], first_player_style: "C", second_player_style: "c")
      end
    end

    test "non-integer dimension" do
      assert_raise ArgumentError, ~r/dimension size must be an integer/, fn ->
        Qi.new([:eight], first_player_style: "C", second_player_style: "c")
      end
    end

    test "zero dimension" do
      assert_raise ArgumentError, "dimension size must be at least 1, got 0", fn ->
        Qi.new([0], first_player_style: "C", second_player_style: "c")
      end
    end

    test "dimension exceeds 255" do
      assert_raise ArgumentError, "dimension size 256 exceeds maximum of 255", fn ->
        Qi.new([256], first_player_style: "C", second_player_style: "c")
      end
    end
  end

  # ===========================================================================
  # new/2 — construction errors (square count)
  # ===========================================================================

  describe "new/2 rejects excessive square count" do
    test "3D 255×255×255" do
      assert_raise ArgumentError, "board exceeds 65025 squares (got 16581375)", fn ->
        Qi.new([255, 255, 255], first_player_style: "C", second_player_style: "c")
      end
    end

    test "3D 255×255×2" do
      assert_raise ArgumentError, "board exceeds 65025 squares (got 130050)", fn ->
        Qi.new([255, 255, 2], first_player_style: "C", second_player_style: "c")
      end
    end

    test "3D just over limit: 255×128×2 = 65280" do
      assert_raise ArgumentError, "board exceeds 65025 squares (got 65280)", fn ->
        Qi.new([255, 128, 2], first_player_style: "C", second_player_style: "c")
      end
    end
  end

  # ===========================================================================
  # new/2 — construction errors (styles)
  # ===========================================================================

  describe "new/2 rejects invalid styles" do
    test "first style nil" do
      assert_raise ArgumentError, "first player style must not be nil", fn ->
        Qi.new([8, 8], first_player_style: nil, second_player_style: "c")
      end
    end

    test "second style nil" do
      assert_raise ArgumentError, "second player style must not be nil", fn ->
        Qi.new([8, 8], first_player_style: "C", second_player_style: nil)
      end
    end

    test "first style not a string" do
      assert_raise ArgumentError, "first player style must be a String", fn ->
        Qi.new([8, 8], first_player_style: :chess, second_player_style: "c")
      end
    end

    test "second style not a string" do
      assert_raise ArgumentError, "second player style must be a String", fn ->
        Qi.new([8, 8], first_player_style: "C", second_player_style: :chess)
      end
    end

    test "first style exceeds 255 bytes" do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "first player style exceeds 255 bytes", fn ->
        Qi.new([8, 8], first_player_style: oversized, second_player_style: "c")
      end
    end

    test "second style exceeds 255 bytes" do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "second player style exceeds 255 bytes", fn ->
        Qi.new([8, 8], first_player_style: "C", second_player_style: oversized)
      end
    end

    test "multi-byte UTF-8 style exceeding limit" do
      # "é" is 2 bytes, 128 × 2 = 256 bytes > 255
      oversized = String.duplicate("é", 128)

      assert_raise ArgumentError, "first player style exceeds 255 bytes", fn ->
        Qi.new([8, 8], first_player_style: oversized, second_player_style: "c")
      end
    end

    test "integer style" do
      assert_raise ArgumentError, "first player style must be a String", fn ->
        Qi.new([8, 8], first_player_style: 0, second_player_style: "c")
      end
    end

    test "false style" do
      assert_raise ArgumentError, "first player style must be a String", fn ->
        Qi.new([1], first_player_style: false, second_player_style: "c")
      end
    end
  end

  # ===========================================================================
  # new/2 — validation order (public API contract per README)
  # ===========================================================================

  describe "new/2 validation order" do
    test "shape error takes priority over style error" do
      assert_raise ArgumentError, "at least one dimension is required", fn ->
        Qi.new([], first_player_style: nil, second_player_style: nil)
      end
    end

    test "dimension values checked before square count" do
      # 256 is invalid dimension, but also would produce huge square count
      assert_raise ArgumentError, "dimension size 256 exceeds maximum of 255", fn ->
        Qi.new([256, 256], first_player_style: "C", second_player_style: "c")
      end
    end

    test "square count checked before styles" do
      assert_raise ArgumentError, ~r/board exceeds 65025 squares/, fn ->
        Qi.new([255, 255, 255], first_player_style: nil, second_player_style: nil)
      end
    end

    test "first style error takes priority over second style error" do
      assert_raise ArgumentError, "first player style must not be nil", fn ->
        Qi.new([8, 8], first_player_style: nil, second_player_style: nil)
      end
    end

    test "style nil checked before style type" do
      assert_raise ArgumentError, "first player style must not be nil", fn ->
        Qi.new([8, 8], first_player_style: nil, second_player_style: :chess)
      end
    end

    test "style type checked before style bytesize" do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "first player style must be a String", fn ->
        Qi.new([8, 8], first_player_style: :chess, second_player_style: oversized)
      end
    end

    test "first style bytesize checked before second style nil" do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "first player style exceeds 255 bytes", fn ->
        Qi.new([8, 8], first_player_style: oversized, second_player_style: nil)
      end
    end
  end

  # ===========================================================================
  # board_diff/2
  # ===========================================================================

  describe "board_diff/2" do
    setup do
      %{pos: Qi.new([8, 8], first_player_style: "C", second_player_style: "c")}
    end

    test "place pieces on empty board", %{pos: pos} do
      pos2 = Qi.board_diff(pos, [{0, "R"}, {4, "K"}, {7, "R"}])
      assert elem(pos2.board, 0) == "R"
      assert elem(pos2.board, 4) == "K"
      assert elem(pos2.board, 7) == "R"
    end

    test "clear a square", %{pos: pos} do
      pos2 = Qi.board_diff(pos, [{0, "K"}])
      pos3 = Qi.board_diff(pos2, [{0, nil}])
      assert elem(pos3.board, 0) == nil
    end

    test "move a piece", %{pos: pos} do
      pos2 = Qi.board_diff(pos, [{12, "P"}])
      pos3 = Qi.board_diff(pos2, [{12, nil}, {28, "P"}])
      assert elem(pos3.board, 12) == nil
      assert elem(pos3.board, 28) == "P"
    end

    test "replace a piece", %{pos: pos} do
      pos2 = Qi.board_diff(pos, [{0, "P"}])
      pos3 = Qi.board_diff(pos2, [{0, "+P"}])
      assert elem(pos3.board, 0) == "+P"
    end

    test "empty changes list", %{pos: pos} do
      pos2 = Qi.board_diff(pos, [])
      assert pos2.board == pos.board
    end

    test "does not modify original", %{pos: pos} do
      _pos2 = Qi.board_diff(pos, [{0, "K"}])
      assert elem(pos.board, 0) == nil
    end

    test "preserves other fields", %{pos: pos} do
      pos2 =
        pos
        |> Qi.first_player_hand_diff([{"P", 1}])
        |> Qi.toggle()

      pos3 = Qi.board_diff(pos2, [{0, "K"}])
      assert pos3.first_player_hand == %{"P" => 1}
      assert pos3.second_player_hand == %{}
      assert pos3.turn == :second
      assert pos3.first_player_style == "C"
      assert pos3.second_player_style == "c"
      assert pos3.shape == [8, 8]
    end

    test "piece at exactly 255 bytes" do
      piece = String.duplicate("A", 255)
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      pos2 = Qi.board_diff(pos, [{0, piece}])
      assert elem(pos2.board, 0) == piece
    end

    test "multi-byte UTF-8 piece within limit" do
      # "é" is 2 bytes, 127 × 2 = 254 bytes ≤ 255
      piece = String.duplicate("é", 127)
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      pos2 = Qi.board_diff(pos, [{0, piece}])
      assert elem(pos2.board, 0) == piece
    end

    test "rejects invalid index" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")

      assert_raise ArgumentError, ~r/invalid flat index/, fn ->
        Qi.board_diff(pos, [{4, "K"}])
      end
    end

    test "rejects non-string piece" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")

      assert_raise ArgumentError, ~r/piece must be a string or nil/, fn ->
        Qi.board_diff(pos, [{0, :K}])
      end
    end

    test "rejects oversized piece" do
      oversized = String.duplicate("A", 256)
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")

      assert_raise ArgumentError, "piece exceeds 255 bytes (got 256)", fn ->
        Qi.board_diff(pos, [{0, oversized}])
      end
    end

    test "rejects multi-byte UTF-8 oversized piece" do
      # "é" is 2 bytes, 128 × 2 = 256 bytes > 255
      oversized = String.duplicate("é", 128)
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")

      assert_raise ArgumentError, "piece exceeds 255 bytes (got 256)", fn ->
        Qi.board_diff(pos, [{0, oversized}])
      end
    end
  end

  # ===========================================================================
  # first_player_hand_diff/2
  # ===========================================================================

  describe "first_player_hand_diff/2" do
    setup do
      %{pos: Qi.new([8, 8], first_player_style: "C", second_player_style: "c")}
    end

    test "add pieces", %{pos: pos} do
      pos2 = Qi.first_player_hand_diff(pos, [{"P", 2}, {"B", 1}])
      assert pos2.first_player_hand == %{"P" => 2, "B" => 1}
    end

    test "remove pieces" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.first_player_hand_diff([{"P", 3}])

      pos2 = Qi.first_player_hand_diff(pos, [{"P", -1}])
      assert pos2.first_player_hand == %{"P" => 2}
    end

    test "remove all copies deletes entry" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.first_player_hand_diff([{"P", 1}])

      pos2 = Qi.first_player_hand_diff(pos, [{"P", -1}])
      assert pos2.first_player_hand == %{}
    end

    test "does not affect second player hand", %{pos: pos} do
      pos2 = Qi.first_player_hand_diff(pos, [{"P", 1}])
      assert pos2.second_player_hand == %{}
    end

    test "does not affect board", %{pos: pos} do
      pos2 = Qi.first_player_hand_diff(pos, [{"P", 1}])
      assert pos2.board == pos.board
    end

    test "piece at exactly 255 bytes", %{pos: pos} do
      piece = String.duplicate("A", 255)
      pos2 = Qi.first_player_hand_diff(pos, [{piece, 1}])
      assert pos2.first_player_hand == %{piece => 1}
    end

    test "rejects non-integer delta", %{pos: pos} do
      assert_raise ArgumentError, ~r/delta must be an integer/, fn ->
        Qi.first_player_hand_diff(pos, [{"P", :one}])
      end
    end

    test "rejects removing absent piece", %{pos: pos} do
      assert_raise ArgumentError, ~r/cannot remove/, fn ->
        Qi.first_player_hand_diff(pos, [{"P", -1}])
      end
    end

    test "rejects oversized piece", %{pos: pos} do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "piece exceeds 255 bytes (got 256)", fn ->
        Qi.first_player_hand_diff(pos, [{oversized, 1}])
      end
    end

    test "rejects multi-byte UTF-8 oversized piece", %{pos: pos} do
      oversized = String.duplicate("é", 128)

      assert_raise ArgumentError, "piece exceeds 255 bytes (got 256)", fn ->
        Qi.first_player_hand_diff(pos, [{oversized, 1}])
      end
    end
  end

  # ===========================================================================
  # second_player_hand_diff/2
  # ===========================================================================

  describe "second_player_hand_diff/2" do
    setup do
      %{pos: Qi.new([8, 8], first_player_style: "C", second_player_style: "c")}
    end

    test "add pieces", %{pos: pos} do
      pos2 = Qi.second_player_hand_diff(pos, [{"p", 2}])
      assert pos2.second_player_hand == %{"p" => 2}
    end

    test "remove pieces" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.second_player_hand_diff([{"p", 3}])

      pos2 = Qi.second_player_hand_diff(pos, [{"p", -2}])
      assert pos2.second_player_hand == %{"p" => 1}
    end

    test "does not affect first player hand", %{pos: pos} do
      pos2 = Qi.second_player_hand_diff(pos, [{"p", 1}])
      assert pos2.first_player_hand == %{}
    end

    test "does not affect board", %{pos: pos} do
      pos2 = Qi.second_player_hand_diff(pos, [{"p", 1}])
      assert pos2.board == pos.board
    end

    test "rejects removing absent piece", %{pos: pos} do
      assert_raise ArgumentError, ~r/cannot remove/, fn ->
        Qi.second_player_hand_diff(pos, [{"p", -1}])
      end
    end

    test "rejects oversized piece", %{pos: pos} do
      oversized = String.duplicate("A", 256)

      assert_raise ArgumentError, "piece exceeds 255 bytes (got 256)", fn ->
        Qi.second_player_hand_diff(pos, [{oversized, 1}])
      end
    end
  end

  # ===========================================================================
  # toggle/1
  # ===========================================================================

  describe "toggle/1" do
    test "first → second" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert Qi.toggle(pos).turn == :second
    end

    test "second → first" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.toggle()

      assert Qi.toggle(pos).turn == :first
    end

    test "double toggle returns to original" do
      pos = Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
      assert pos |> Qi.toggle() |> Qi.toggle() |> Map.get(:turn) == :first
    end

    test "preserves board" do
      pos =
        Qi.new([4], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "K"}])

      pos2 = Qi.toggle(pos)
      assert pos2.board == pos.board
    end

    test "preserves hands" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.first_player_hand_diff([{"P", 1}])
        |> Qi.second_player_hand_diff([{"p", 2}])

      pos2 = Qi.toggle(pos)
      assert pos2.first_player_hand == %{"P" => 1}
      assert pos2.second_player_hand == %{"p" => 2}
    end

    test "preserves styles and shape" do
      pos = Qi.new([9, 9], first_player_style: "S", second_player_style: "s")
      pos2 = Qi.toggle(pos)
      assert pos2.first_player_style == "S"
      assert pos2.second_player_style == "s"
      assert pos2.shape == [9, 9]
    end
  end

  # ===========================================================================
  # to_nested/1
  # ===========================================================================

  describe "to_nested/1" do
    test "1D" do
      pos =
        Qi.new([3], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "K"}, {2, "k"}])

      assert Qi.to_nested(pos) == ["K", nil, "k"]
    end

    test "2D" do
      pos =
        Qi.new([2, 3], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {5, "f"}])

      assert Qi.to_nested(pos) == [["a", nil, nil], [nil, nil, "f"]]
    end

    test "3D" do
      pos = Qi.new([2, 2, 2], first_player_style: "C", second_player_style: "c")

      assert Qi.to_nested(pos) == [
               [[nil, nil], [nil, nil]],
               [[nil, nil], [nil, nil]]
             ]
    end

    test "empty board" do
      pos = Qi.new([3, 3], first_player_style: "C", second_player_style: "c")

      assert Qi.to_nested(pos) == [
               [nil, nil, nil],
               [nil, nil, nil],
               [nil, nil, nil]
             ]
    end
  end

  # ===========================================================================
  # Cardinality enforcement (cross-location)
  # ===========================================================================

  describe "cardinality enforcement" do
    test "board full, adding to hand raises" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {1, "b"}])

      assert_raise ArgumentError, ~r/too many pieces for board size/, fn ->
        Qi.first_player_hand_diff(pos, [{"c", 1}])
      end
    end

    test "board full, adding to second hand raises" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {1, "b"}])

      assert_raise ArgumentError, ~r/too many pieces for board size/, fn ->
        Qi.second_player_hand_diff(pos, [{"c", 1}])
      end
    end

    test "hand pieces count toward cardinality" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.first_player_hand_diff([{"P", 1}])
        |> Qi.second_player_hand_diff([{"p", 1}])

      # 0 on board + 1 first hand + 1 second hand = 2 = square_count → OK
      assert pos.first_player_hand == %{"P" => 1}

      # Adding one more piece anywhere would exceed 2
      assert_raise ArgumentError, ~r/too many pieces for board size/, fn ->
        Qi.board_diff(pos, [{0, "K"}])
      end
    end

    test "p == n is valid" do
      pos =
        Qi.new([4], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {1, "b"}])
        |> Qi.first_player_hand_diff([{"c", 1}])
        |> Qi.second_player_hand_diff([{"d", 1}])

      # 2 on board + 1 + 1 = 4 = square_count
      assert tuple_size(pos.board) == 4
    end

    test "removing from board frees capacity for hand" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {1, "b"}])
        |> Qi.board_diff([{0, nil}])

      # 1 on board → can add 1 to hand
      pos2 = Qi.first_player_hand_diff(pos, [{"c", 1}])
      assert pos2.first_player_hand == %{"c" => 1}
    end

    test "removing from hand frees capacity for board" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.first_player_hand_diff([{"P", 2}])

      # 0 on board + 2 in hand = 2 → board_diff adding would fail
      assert_raise ArgumentError, ~r/too many pieces/, fn ->
        Qi.board_diff(pos, [{0, "K"}])
      end

      # Remove one from hand, then board_diff should work
      pos2 = Qi.first_player_hand_diff(pos, [{"P", -1}])
      pos3 = Qi.board_diff(pos2, [{0, "K"}])
      assert elem(pos3.board, 0) == "K"
    end

    test "cardinality error message includes counts" do
      pos =
        Qi.new([2], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{0, "a"}, {1, "b"}])

      assert_raise ArgumentError, "too many pieces for board size (3 pieces, 2 squares)", fn ->
        Qi.first_player_hand_diff(pos, [{"c", 1}])
      end
    end
  end

  # ===========================================================================
  # Piping / composition
  # ===========================================================================

  describe "pipe composition" do
    test "simple move: slide a piece" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{52, "P"}])
        |> Qi.board_diff([{52, nil}, {36, "P"}])
        |> Qi.toggle()

      assert elem(pos.board, 52) == nil
      assert elem(pos.board, 36) == "P"
      assert pos.turn == :second
    end

    test "capture: overwrite + hand + toggle" do
      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{52, "P"}, {36, "p"}])
        |> Qi.board_diff([{52, nil}, {36, "P"}])
        |> Qi.first_player_hand_diff([{"p", 1}])
        |> Qi.toggle()

      assert elem(pos.board, 52) == nil
      assert elem(pos.board, 36) == "P"
      assert pos.first_player_hand == %{"p" => 1}
      assert pos.turn == :second
    end

    test "shogi drop: hand → board" do
      pos =
        Qi.new([9, 9], first_player_style: "S", second_player_style: "s")
        |> Qi.first_player_hand_diff([{"P", 1}])
        |> Qi.first_player_hand_diff([{"P", -1}])
        |> Qi.board_diff([{40, "P"}])
        |> Qi.toggle()

      assert pos.first_player_hand == %{}
      assert elem(pos.board, 40) == "P"
      assert pos.turn == :second
    end

    test "multiple turns" do
      pos =
        Qi.new([3, 3], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff([{4, "K"}, {0, "k"}])
        # Turn 1: first player moves K from 4 to 5
        |> Qi.board_diff([{4, nil}, {5, "K"}])
        |> Qi.toggle()
        # Turn 2: second player moves k from 0 to 1
        |> Qi.board_diff([{0, nil}, {1, "k"}])
        |> Qi.toggle()

      assert elem(pos.board, 5) == "K"
      assert elem(pos.board, 1) == "k"
      assert elem(pos.board, 4) == nil
      assert elem(pos.board, 0) == nil
      assert pos.turn == :first
    end
  end

  # ===========================================================================
  # Realistic game scenarios
  # ===========================================================================

  describe "chess scenario" do
    test "full starting position" do
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
      pawns_w = for f <- 48..55, do: {f, "P"}

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

      pos =
        Qi.new([8, 8], first_player_style: "C", second_player_style: "c")
        |> Qi.board_diff(back_rank_b ++ pawns_b ++ pawns_w ++ back_rank_w)

      assert elem(pos.board, 4) == "k"
      assert elem(pos.board, 60) == "K"
      assert elem(pos.board, 32) == nil
      assert pos.turn == :first
    end
  end

  describe "shogi scenario (Crazyhouse-like)" do
    test "capture and drop cycle" do
      pos =
        Qi.new([9, 9], first_player_style: "S", second_player_style: "s")
        |> Qi.board_diff([{40, "K"}, {4, "k"}, {31, "p"}])

      # First player captures pawn on 31
      pos2 =
        pos
        |> Qi.board_diff([{40, nil}, {31, "K"}])
        |> Qi.first_player_hand_diff([{"p", 1}])
        |> Qi.toggle()

      assert elem(pos2.board, 31) == "K"
      assert pos2.first_player_hand == %{"p" => 1}
      assert pos2.turn == :second

      # Second player passes (just toggle)
      pos3 = Qi.toggle(pos2)
      assert pos3.turn == :first

      # First player drops captured pawn
      pos4 =
        pos3
        |> Qi.first_player_hand_diff([{"p", -1}])
        |> Qi.board_diff([{50, "p"}])
        |> Qi.toggle()

      assert pos4.first_player_hand == %{}
      assert elem(pos4.board, 50) == "p"
      assert pos4.turn == :second
    end
  end

  describe "placement game scenario" do
    test "pieces start in hands, placed onto board" do
      pos =
        Qi.new([3, 3], first_player_style: "G", second_player_style: "g")
        |> Qi.first_player_hand_diff([{"X", 3}])
        |> Qi.second_player_hand_diff([{"O", 3}])

      # Turn 1: first places X
      pos2 =
        pos
        |> Qi.first_player_hand_diff([{"X", -1}])
        |> Qi.board_diff([{4, "X"}])
        |> Qi.toggle()

      # Turn 2: second places O
      pos3 =
        pos2
        |> Qi.second_player_hand_diff([{"O", -1}])
        |> Qi.board_diff([{0, "O"}])
        |> Qi.toggle()

      assert pos3.first_player_hand == %{"X" => 2}
      assert pos3.second_player_hand == %{"O" => 2}
      assert elem(pos3.board, 4) == "X"
      assert elem(pos3.board, 0) == "O"
      assert pos3.turn == :first
    end
  end

  # ===========================================================================
  # Immutability
  # ===========================================================================

  describe "immutability" do
    test "board_diff returns new struct" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      pos2 = Qi.board_diff(pos, [{0, "K"}])
      refute pos === pos2
      assert elem(pos.board, 0) == nil
    end

    test "hand_diff returns new struct" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      pos2 = Qi.first_player_hand_diff(pos, [{"P", 1}])
      refute pos === pos2
      assert pos.first_player_hand == %{}
    end

    test "toggle returns new struct" do
      pos = Qi.new([4], first_player_style: "C", second_player_style: "c")
      pos2 = Qi.toggle(pos)
      refute pos === pos2
      assert pos.turn == :first
    end
  end
end
