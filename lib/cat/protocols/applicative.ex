defprotocol Cat.Applicative do
  @moduledoc """
  Applicative defines
    * `pure(t(any), x) :: t(x)`
    * `ap(t((x -> y)), t(x)) :: t(y)`
    * `product(t(x), t(y)) :: t({x, y})`

  **It must also be `Functor`.**

  Default implementations (at `Applicative.Default`):
    * `product(t(x), t(y)) :: t({x, y})`

  Module provides implementations for:
    * `List`
  """

  @type t(_x) :: term

  @spec pure(t(any), x) :: t(x) when x: var
  def pure(example, x)

  @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
  def ap(tf, tx)

  @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
  def product(tx, ty)
end

alias Cat.{Applicative, Functor}

defmodule Cat.Applicative.Arrow do
  @spec pure(Applicative.t(any)) :: (x -> Applicative.t(x)) when x: var
  def pure(example), do: &Applicative.pure(example, &1)

  @spec ap(Applicative.t((x -> y))) :: (Applicative.t(x) -> Applicative.t(y)) when x: var, y: var
  def ap(tf), do: &Applicative.ap(tf, &1)
end

defmodule Cat.Applicative.Default do
  @moduledoc false

  @spec product(Applicative.t(x), Applicative.t(y)) :: Applicative.t({x, y}) when x: var, y: var
  def product(tx, ty) do
    fs = Functor.map(tx, fn x -> (fn y -> {x, y} end) end)
    Applicative.ap(fs, ty)
  end
end

defimpl Applicative, for: List do
  @type t(x) :: [x]

  @spec pure([any], x) :: [x] when x: var
  def pure(_, x), do: [x]

  @spec ap([(x -> y)], [x]) :: [y] when x: var, y: var
  def ap(tf, tx), do:  _ap(tf, tx, tx, [])

  defp _ap(tf, tx, fx0, acc)
  defp _ap([tfh | _]=tf, [txh | txt], tx0, acc), do: _ap(tf, txt, tx0, [tfh.(txh) | acc])
  defp _ap([_ | tft], [], tx0, acc), do: _ap(tft, tx0, tx0, acc)
  defp _ap([], _, _, acc), do: Enum.reverse(acc)

  @spec product([x], [y]) :: [{x, y}] when x: var, y: var
  defdelegate product(tx, ty), to: Applicative.Default
end
