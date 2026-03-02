defmodule Qi.HandsTest do
  use ExUnit.Case, async: true

  alias Qi.Hands

  # ===========================================================================
  # Constants
  # ===========================================================================

  describe "max_piece_bytesize/0" do
    test "returns 255" do
      assert Hands.max_piece_bytesize() == 255
    end
  end

  # ===========================================================================
  # new/0
  # ===========================================================================

  describe "new/0" do
    test "returns an empty map" do
      assert Hands.new() == %{}
    end
  end

  # ===========================================================================
  # diff/2 — adding pieces
  # ===========================================================================

  describe "diff/2 adding pieces" do
    test "add one piece to empty hand" do
      assert {:ok, %{"P" => 1}, 1} = Hands.diff(%{}, [{"P", 1}])
    end

    test "add multiple copies of one piece" do
      assert {:ok, %{"P" => 3}, 3} = Hands.diff(%{}, [{"P", 3}])
    end

    test "add different pieces" do
      assert {:ok, hand, 3} = Hands.diff(%{}, [{"P", 2}, {"B", 1}])
      assert hand == %{"P" => 2, "B" => 1}
    end

    test "add to existing pieces" do
      assert {:ok, %{"P" => 3}, 2} = Hands.diff(%{"P" => 1}, [{"P", 2}])
    end

    test "add new piece type to non-empty hand" do
      assert {:ok, hand, 1} = Hands.diff(%{"P" => 2}, [{"B", 1}])
      assert hand == %{"P" => 2, "B" => 1}
    end

    test "pieces with special characters" do
      assert {:ok, hand, 2} = Hands.diff(%{}, [{"+P", 1}, {"C:B", 1}])
      assert hand == %{"+P" => 1, "C:B" => 1}
    end

    test "piece at exactly 255 bytes" do
      piece = String.duplicate("A", 255)
      assert {:ok, hand, 1} = Hands.diff(%{}, [{piece, 1}])
      assert hand == %{piece => 1}
    end

    test "empty string piece" do
      assert {:ok, %{"" => 1}, 1} = Hands.diff(%{}, [{"", 1}])
    end

    test "multi-byte UTF-8 piece within limit" do
      # "é" is 2 bytes, 127 × 2 = 254 bytes ≤ 255
      piece = String.duplicate("é", 127)
      assert {:ok, hand, 1} = Hands.diff(%{}, [{piece, 1}])
      assert hand == %{piece => 1}
    end
  end

  # ===========================================================================
  # diff/2 — removing pieces
  # ===========================================================================

  describe "diff/2 removing pieces" do
    test "remove one copy, some remain" do
      assert {:ok, %{"P" => 1}, -1} = Hands.diff(%{"P" => 2}, [{"P", -1}])
    end

    test "remove all copies (entry deleted)" do
      assert {:ok, hand, -1} = Hands.diff(%{"P" => 1}, [{"P", -1}])
      assert hand == %{}
    end

    test "remove all copies of one piece, keep others" do
      assert {:ok, hand, -2} = Hands.diff(%{"P" => 2, "B" => 1}, [{"P", -2}])
      assert hand == %{"B" => 1}
    end

    test "remove multiple piece types" do
      hand = %{"P" => 3, "B" => 1, "N" => 2}
      assert {:ok, new_hand, -3} = Hands.diff(hand, [{"P", -1}, {"B", -1}, {"N", -1}])
      assert new_hand == %{"P" => 2, "N" => 1}
    end
  end

  # ===========================================================================
  # diff/2 — mixed add and remove
  # ===========================================================================

  describe "diff/2 mixed operations" do
    test "add one, remove another" do
      assert {:ok, hand, 0} = Hands.diff(%{"B" => 1}, [{"B", -1}, {"P", 1}])
      assert hand == %{"P" => 1}
    end

    test "net positive delta" do
      assert {:ok, hand, 1} = Hands.diff(%{"P" => 1}, [{"P", -1}, {"B", 1}, {"N", 1}])
      assert hand == %{"B" => 1, "N" => 1}
    end

    test "net negative delta" do
      assert {:ok, hand, -2} =
               Hands.diff(%{"P" => 2, "B" => 1}, [{"P", -2}, {"B", -1}, {"N", 1}])

      assert hand == %{"N" => 1}
    end
  end

  # ===========================================================================
  # diff/2 — zero delta (no-op)
  # ===========================================================================

  describe "diff/2 zero delta" do
    test "zero delta on empty hand" do
      assert {:ok, %{}, 0} = Hands.diff(%{}, [{"P", 0}])
    end

    test "zero delta on non-empty hand" do
      assert {:ok, %{"P" => 2}, 0} = Hands.diff(%{"P" => 2}, [{"P", 0}])
    end

    test "zero delta for absent piece" do
      assert {:ok, %{}, 0} = Hands.diff(%{}, [{"X", 0}])
    end

    test "zero delta bypasses bytesize check" do
      # 256-byte piece with delta 0 — should be a no-op, not an error
      oversized = String.duplicate("A", 256)
      assert {:ok, %{}, 0} = Hands.diff(%{}, [{oversized, 0}])
    end

    test "empty changes list" do
      assert {:ok, %{"P" => 1}, 0} = Hands.diff(%{"P" => 1}, [])
    end

    test "empty changes on empty hand" do
      assert {:ok, %{}, 0} = Hands.diff(%{}, [])
    end
  end

  # ===========================================================================
  # diff/2 — does not modify original
  # ===========================================================================

  describe "diff/2 immutability" do
    test "original hand is unchanged" do
      original = %{"P" => 1}
      {:ok, _new, _delta} = Hands.diff(original, [{"P", 1}])
      assert original == %{"P" => 1}
    end
  end

  # ===========================================================================
  # diff/2 — error: oversized pieces
  # ===========================================================================

  describe "diff/2 rejects oversized pieces" do
    test "piece at 256 bytes" do
      piece = String.duplicate("A", 256)

      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 256)"}} =
               Hands.diff(%{}, [{piece, 1}])
    end

    test "piece far over limit" do
      piece = String.duplicate("X", 1000)

      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 1000)"}} =
               Hands.diff(%{}, [{piece, 1}])
    end

    test "multi-byte UTF-8 piece exceeding limit" do
      # "é" is 2 bytes, 128 × 2 = 256 bytes > 255
      piece = String.duplicate("é", 128)

      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 256)"}} =
               Hands.diff(%{}, [{piece, 1}])
    end

    test "oversized piece with negative delta" do
      piece = String.duplicate("A", 256)

      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 256)"}} =
               Hands.diff(%{}, [{piece, -1}])
    end

    test "valid change before oversized piece" do
      oversized = String.duplicate("A", 256)

      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 256)"}} =
               Hands.diff(%{}, [{"P", 1}, {oversized, 1}])
    end
  end

  # ===========================================================================
  # diff/2 — error: removing more than present
  # ===========================================================================

  describe "diff/2 rejects removing more pieces than present" do
    test "remove from empty hand" do
      assert {:error, %ArgumentError{message: "cannot remove P: not found in hand"}} =
               Hands.diff(%{}, [{"P", -1}])
    end

    test "remove more than available" do
      assert {:error, %ArgumentError{message: "cannot remove P: not found in hand"}} =
               Hands.diff(%{"P" => 1}, [{"P", -2}])
    end

    test "remove piece not in hand" do
      assert {:error, %ArgumentError{message: "cannot remove B: not found in hand"}} =
               Hands.diff(%{"P" => 1}, [{"B", -1}])
    end

    test "valid change before invalid removal" do
      assert {:error, %ArgumentError{message: "cannot remove B: not found in hand"}} =
               Hands.diff(%{}, [{"P", 1}, {"B", -1}])
    end
  end

  # ===========================================================================
  # diff/2 — error: non-integer delta
  # ===========================================================================

  describe "diff/2 rejects non-integer deltas" do
    test "atom delta" do
      assert {:error, %ArgumentError{message: "delta must be an integer, got :one for piece P"}} =
               Hands.diff(%{}, [{"P", :one}])
    end

    test "float delta" do
      assert {:error, %ArgumentError{message: "delta must be an integer, got 1.0 for piece P"}} =
               Hands.diff(%{}, [{"P", 1.0}])
    end

    test "string delta" do
      assert {:error, %ArgumentError{message: "delta must be an integer, got \"1\" for piece P"}} =
               Hands.diff(%{}, [{"P", "1"}])
    end

    test "nil delta" do
      assert {:error, %ArgumentError{message: "delta must be an integer, got nil for piece P"}} =
               Hands.diff(%{}, [{"P", nil}])
    end
  end

  # ===========================================================================
  # diff/2 — error: non-string piece
  # ===========================================================================

  describe "diff/2 rejects non-string pieces" do
    test "atom piece" do
      assert {:error, %ArgumentError{message: "piece must be a string, got :P"}} =
               Hands.diff(%{}, [{:P, 1}])
    end

    test "integer piece" do
      assert {:error, %ArgumentError{message: "piece must be a string, got 1"}} =
               Hands.diff(%{}, [{1, 1}])
    end

    test "nil piece" do
      assert {:error, %ArgumentError{message: "piece must be a string, got nil"}} =
               Hands.diff(%{}, [{nil, 1}])
    end

    test "tuple piece" do
      assert {:error, %ArgumentError{message: "piece must be a string, got {:pawn, :first}"}} =
               Hands.diff(%{}, [{{:pawn, :first}, 1}])
    end
  end

  # ===========================================================================
  # diff/2 — validation order
  # ===========================================================================

  describe "diff/2 validation order" do
    test "piece type checked before piece bytesize" do
      # atom is not a string — type error, not bytesize error
      assert {:error, %ArgumentError{message: "piece must be a string, got :X"}} =
               Hands.diff(%{}, [{:X, 1}])
    end

    test "piece bytesize checked before delta type" do
      oversized = String.duplicate("A", 256)

      # Bytesize is only checked when delta is a valid integer.
      # With a non-integer delta, the delta type clause matches first.
      assert {:error, %ArgumentError{message: "piece exceeds 255 bytes (got 256)"}} =
               Hands.diff(%{}, [{oversized, 1}])
    end

    test "zero delta bypasses all piece validation" do
      oversized = String.duplicate("A", 256)
      assert {:ok, %{}, 0} = Hands.diff(%{}, [{oversized, 0}])
    end
  end

  # ===========================================================================
  # piece_count/1
  # ===========================================================================

  describe "piece_count/1" do
    test "empty hand" do
      assert Hands.piece_count(%{}) == 0
    end

    test "single piece type" do
      assert Hands.piece_count(%{"P" => 3}) == 3
    end

    test "multiple piece types" do
      assert Hands.piece_count(%{"P" => 3, "B" => 1, "N" => 2}) == 6
    end

    test "one of each" do
      assert Hands.piece_count(%{"P" => 1, "B" => 1}) == 2
    end
  end
end
