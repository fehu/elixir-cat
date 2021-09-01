alias Cat.{Fun, Functor}
alias Cat.Laws.Law
require Fun

defmodule Cat.Laws.FunctorLaws do
  @moduledoc false

  @typep t(_x) :: any

  @spec identity(t(a)) :: Law.eq?(t(a)) when a: var
  def identity(ta), do:
    Law.eq? Functor.map(ta, Fun.id), ta

  @spec composition(t(a), (a -> b), (b -> c)) :: Law.eq?(t(c)) when a: var, b: var, c: var
  def composition(ta, f, g), do:
    Law.eq? Functor.map(Functor.map(ta, f), g),
            Functor.map(ta, Fun.compose(g, f))

end
