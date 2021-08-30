defprotocol Cat.Applicative do
  @moduledoc """
  Applicative defines
    * `pure(t(any), a) :: t(a)`
    * `ap(t((a -> b)), t(a)) :: t(b)`
    * `product(t(a), t(b)) :: t({a, b})`
    * `product_l(t(a), t(any)) :: t(a)`
    * `product_r(t(any), t(a)) :: t(a)`
    * `map2(t(a), t(b), (a, b -> c)) :: t(c)`

  **It must also be `Functor`.**

  Default implementations (at `Applicative.Default`):
    * `product(t(a), t(b)) :: t({a, b})`
    * `product_l(t(a), t(any)) :: t(a)`
    * `product_r(t(any), t(a)) :: t(a)`
    * `map2(t(a), t(b), (a, b -> c)) :: t(c)`

  Module provides implementations for:
    * `List`
  """

  @type t(_x) :: term

  @spec pure(t(any), a) :: t(a) when a: var
  def pure(example, a)

  @spec ap(t((a -> b)), t(a)) :: t(b) when a: var, b: var
  def ap(tf, ta)

  @spec product(t(a), t(b)) :: t({a, b}) when a: var, b: var
  def product(ta, tb)

  @spec product_l(t(a), t(any)) :: t(a) when a: var
  def product_l(ta, tb)

  @spec product_r(t(any), t(b)) :: t(b) when b: var
  def product_r(ta, tb)

  @spec map2(t(a), t(b), (a, b -> c)) :: t(c) when a: var, b: var, c: var
  def map2(ta, tb, f)
end

alias Cat.{Applicative, Functor}

defmodule Cat.Applicative.Arrow do
  @spec pure(Applicative.t(any)) :: (a -> Applicative.t(a)) when a: var
  def pure(example), do: &Applicative.pure(example, &1)

  @spec ap(Applicative.t((a -> b))) :: (Applicative.t(a) -> Applicative.t(b)) when a: var, b: var
  def ap(tf), do: &Applicative.ap(tf, &1)

  @spec product_l(Applicative.t(any)) :: (Applicative.t(a) -> Applicative.t(a)) when a: var
  def product_l(tb), do: &Applicative.product_l(&1, tb)

  @spec product_r(Applicative.t(any)) :: (Applicative.t(b) -> Applicative.t(b)) when b: var
  def product_r(ta), do: &Applicative.product_r(ta, &1)

  @spec map2((a, b -> c)) :: (Applicative.t(a), Applicative.t(b) -> Applicative.t(c)) when a: var, b: var, c: var
  def map2(f), do: &Applicative.map2(&1, &2, f)
end

defmodule Cat.Applicative.Default do
  @moduledoc false

  alias Cat.Fun
  require Fun

  @spec product(Applicative.t(a), Applicative.t(b)) :: Applicative.t({a, b}) when a: var, b: var
  def product(ta, tb) do
    fs = Functor.map(ta, fn a -> (fn b -> {a, b} end) end)
    Applicative.ap(fs, tb)
  end

  @spec product_l(Applicative.t(a), Applicative.t(any)) :: Applicative.t(a) when a: var
  def product_l(ta, tb), do: Applicative.map2(ta, tb, fn a, _ -> a end)

  @spec product_r(Applicative.t(any), Applicative.t(b)) :: Applicative.t(b) when b: var
  def product_r(ta, tb), do: Applicative.map2(ta, tb, fn _, b -> b end)

  @spec map2(Applicative.t(a), Applicative.t(b), (a, b -> c)) :: Applicative.t(c) when a: var, b: var, c: var
  def map2(ta, tb, f), do: Functor.map(Applicative.product(ta, tb), Fun.tupled(f))

  defmodule FromMonad do
    alias Cat.Monad

    @spec ap(Applicative.t((a -> b)), Applicative.t(a)) :: Applicative.t(b) when a: var, b: var
    def ap(tf, ta), do:
      Monad.flat_map tf, fn f ->
        Functor.map(ta, f)
      end
  end
end

defimpl Applicative, for: List do
  @type t(a) :: [a]

  @spec pure([any], a) :: [a] when a: var
  def pure(_, a), do: [a]

  @spec ap([(a -> b)], [a]) :: [b] when a: var, b: var
  def ap(tf, ta), do:  _ap(tf, ta, ta, [])

  defp _ap(tf, ta, fx0, acc)
  defp _ap([tfh | _]=tf, [tah | tat], ta0, acc), do: _ap(tf, tat, ta0, [tfh.(tah) | acc])
  defp _ap([_ | tft], [], ta0, acc), do: _ap(tft, ta0, ta0, acc)
  defp _ap([], _, _, acc), do: Enum.reverse(acc)

  defdelegate product(ta, tb), to: Applicative.Default
  defdelegate product_l(ta, tb), to: Applicative.Default
  defdelegate product_r(ta, tb), to: Applicative.Default
  defdelegate map2(ta, tb, f), to: Applicative.Default
end
