alias Cat.Laws.Law

alias ExUnit.Assertions
require Assertions

defmodule Cat.Laws.Law.ExUnit do
  @moduledoc false

  # Typespec corresponds to `Law.check/4`
  def assert(arg_gen, law, test_eq \\ &Law.default_test_eq/1, opts \\ []) do
    {result, message} = Law.check(arg_gen, law, test_eq, opts)
    Assertions.assert result == :passed, message
  end
end
