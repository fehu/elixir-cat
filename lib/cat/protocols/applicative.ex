defprotocol Cat.Applicative do
  @moduledoc """
  Applicative defines
    * `pure(t(any), a) :: t(a)`
    * `ap(t((a -> b)), t(a)) :: t(b)`
    * `product(t(a), t(b)) :: t({a, b})`

  **It must also be `Functor`.**

  Default implementations (at `Applicative.Default`):
    * `product(t(a), t(b)) :: t({a, b})`

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
end

alias Cat.{Applicative, Functor}

defmodule Cat.Applicative.Arrow do
  @spec pure(Applicative.t(any)) :: (a -> Applicative.t(a)) when a: var
  def pure(example), do: &Applicative.pure(example, &1)

  @spec ap(Applicative.t((a -> b))) :: (Applicative.t(a) -> Applicative.t(b)) when a: var, b: var
  def ap(tf), do: &Applicative.ap(tf, &1)
end

defmodule Cat.Applicative.Default do
  @moduledoc false

  @spec product(Applicative.t(a), Applicative.t(b)) :: Applicative.t({a, b}) when a: var, b: var
  def product(ta, tb) do
    fs = Functor.map(ta, fn a -> (fn b -> {a, b} end) end)
    Applicative.ap(fs, tb)
  end

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

  @spec product([a], [b]) :: [{a, b}] when a: var, b: var
  defdelegate product(ta, tb), to: Applicative.Default
end
