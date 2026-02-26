defmodule QiTest do
  use ExUnit.Case, async: true

  doctest Qi
  doctest Qi.Board
  doctest Qi.Hands
  doctest Qi.Position
  doctest Qi.Styles
end
