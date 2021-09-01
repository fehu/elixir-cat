alias Cat.{Fun, Functor}
alias Cat.Laws.Law.ExUnit, as: LawTest
alias Cat.Laws.FunctorLaws, as: Laws
alias Test.Gen

require Fun

defmodule Cat.FunctorTest do
  use ExUnit.Case

  @header "Functor implementation for List: "

  test @header <> "identity law" do
    gen = Gen.list(Gen.non_neg_int)
    LawTest.assert(gen, &Laws.identity/1)
  end

  test @header <> "composition law" do
    gen = Functor.map Gen.list(Gen.non_neg_int), fn list -> {list, &(&1 + 5), &{&1 * 3}} end
    LawTest.assert(gen, Fun.tupled(&Laws.composition/3))
  end

end
