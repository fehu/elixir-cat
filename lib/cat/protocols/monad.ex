defprotocol Cat.Monad do
  @moduledoc """
  Monad defines `flat_map(t(a), (a -> t(b))) :: t(b)`.

  **It must also be `Applicative` and `Functor`.**

  Module provides implementations for:
    * `List`
  """

  @type t(_x) :: term

  @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: var, b: var
  def flat_map(ta, f)

  @spec flat_tap(t(a), (a -> t(no_return))) :: t(a) when a: var
  def flat_tap(ta, f)
end

alias Cat.{Functor, Monad}
alias Cat.Fun

require Fun

defmodule Cat.Monad.Arrow do
  @spec flat_map((a -> Monad.t(b))) :: (Monad.t(a) -> Monad.t(b)) when a: var, b: var
  def flat_map(f), do: &Monad.flat_map(&1, f)

  @spec flat_tap((a -> Monad.t(no_return))) :: (Monad.t(a) -> Monad.t(a)) when a: var
  def flat_tap(f), do: &Monad.flat_tap(&1, f)
end

defmodule Cat.Monad.Default do
  @spec flat_tap(Monad.t(a), (a -> Monad.t(no_return))) :: Monad.t(a) when a: var
  def flat_tap(ta, f) do
    Monad.flat_map ta, fn a ->
      Functor.map f.(a), Fun.const_inline(a)
    end
  end
end

defimpl Monad, for: List do
  @type t(a) :: [a]

  @spec flat_map([a], (a -> [b])) :: [b] when a: var, b: var
  def flat_map(ta, f), do: _flat_map(ta, f, [])

  @spec _flat_map([a], (a -> [b]), [b]) :: [b] when a: var, b: var
  defp _flat_map(ta, f, acc)
  defp _flat_map([], _, acc), do: acc
  defp _flat_map([h | t], f, acc), do: _flat_map(t, f, acc ++ f.(h))

  @spec flat_tap([a], (a -> [no_return])) :: [a] when a: var
  defdelegate flat_tap(ta, f), to: Cat.Monad.Default
end
