defprotocol Cat.Monad do
  @moduledoc """
  Monad defines `flat_map(t(x), (x -> t(y))) :: t(y)`.

  **It must also be `Applicative` and `Functor`.**

  Module provides implementations for:
    * `List`
  """

  @type t(_x) :: term

  @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
  def flat_map(tx, f)
end

alias Cat.Monad

defmodule Cat.Monad.Arrow do
  @spec flat_map((x -> Monad.t(y))) :: (Monad.t(x) -> Monad.t(y)) when x: var, y: var
  def flat_map(f), do: &Monad.flat_map(&1, f)
end

defimpl Monad, for: List do
  @type t(x) :: [x]

  @spec flat_map([x], (x -> [y])) :: [y] when x: var, y: var
  def flat_map(tx, f), do: _flat_map(tx, f, [])

  @spec _flat_map([x], (x -> [y]), [y]) :: [y] when x: var, y: var
  defp _flat_map(tx, f, acc)
  defp _flat_map([], _, acc), do: acc
  defp _flat_map([h | t], f, acc), do: _flat_map(t, f, acc ++ f.(h))
end
