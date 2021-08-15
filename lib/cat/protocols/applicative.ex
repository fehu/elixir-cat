defprotocol Applicative do
  @moduledoc """
  Applicative is a Functor that defines
    * `pure(x) :: t(x) when x: var`
    * `ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var`

  Default implementation of `product(t(x), t(y)) :: t({x, y}) when x: var, y: var`
    can be found at `Applicative.Default`.

  Module provides implementations for:
    * `List`
  """

  @type t(_x) :: term

  ## Functor ##

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(tx, f)

  ## Applicative ##

  @spec pure(x) :: t(x) when x: var
  def pure(x)

  @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
  def ap(tf, tx)

  @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
  def product(tx, ty)
end

defmodule Applicative.F do
#  @spec map((x -> y)) :: (t(x) -> t(y)) when x: var, y: var
#  def map(f)
#
#  @spec pure(module()) :: t(x) when x: var
#  def pure(m)
#
#  @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
#  def ap(tf, tx)
end

defmodule Applicative.Default do
  @moduledoc false

  @spec product(Applicative.t(x), Applicative.t(y)) :: Applicative.t({x, y}) when x: var, y: var
  def product(tx, ty) do
    fs = Applicative.map(tx, fn x -> (fn y -> {x, y} end) end)
    Applicative.ap(fs, ty)
  end
end

defimpl Applicative, for: List do
  @type t(x) :: [x]

  @spec map([x], (x -> y)) :: [y] when x: var, y: var
  defdelegate map(tx, f), to: Functor
#  def map(tx, f), do: Functor.map(tx, f)

  @spec pure(x) :: [x] when x: var
  def pure(x), do: [x]

  @spec ap([(x -> y)], [x]) :: [y] when x: var, y: var
  def ap(tf, tx), do:  _ap(tf, tx, tx, [])

  defp _ap(tf, tx, fx0, acc)
  defp _ap([tfh | _]=tf, [txh | txt], tx0, acc), do: _ap(tf, txt, tx0, [tfh.(txh) | acc])
  defp _ap([_ | tft], [], tx0, acc), do: _ap(tft, tx0, tx0, acc)
  defp _ap([], _, _, acc), do: Enum.reverse(acc)

  @spec product([x], [y]) :: [{x, y}] when x: var, y: var
  defdelegate product(tx, ty), to: Applicative.Default
end
