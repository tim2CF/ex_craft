defmodule ExCraftTest do
  use ExUnit.Case
  doctest ExCraft

  test "greets the world" do
    assert ExCraft.hello() == :world
  end
end
