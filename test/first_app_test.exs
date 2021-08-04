defmodule FirstAppTest do
  use ExUnit.Case
  doctest FirstApp

  test "greets the world" do
    assert FirstApp.hello() == :world
  end
end
