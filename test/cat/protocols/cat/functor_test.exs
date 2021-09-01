alias Cat.{Fun, Functor}
alias Cat.Laws.Law
alias Cat.Laws.FunctorLaws, as: Laws
alias Test.Gen

require Fun

defmodule Cat.FunctorTest do
  use ExUnit.Case

  @header "Functor implementation for List: "

  test @header <> "identity law" do
    gen = Gen.list(Gen.non_neg_int)
    {result, message} = Law.check(gen, &Laws.identity/1)
    assert result == :passed, message
  end

  test @header <> "composition law" do
    gen = Functor.map Gen.list(Gen.non_neg_int), fn list -> {list, &(&1 + 5), &{&1 * 3}} end
    {result, message} = Law.check(gen, Fun.tupled(&Laws.composition/3))
    assert result == :passed, message
  end

end
