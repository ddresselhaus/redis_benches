defmodule RedisBenchesTest do
  use ExUnit.Case
  doctest RedisBenches

  test "greets the world" do
    assert RedisBenches.hello() == :world
  end
end
