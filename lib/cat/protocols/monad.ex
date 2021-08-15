defprotocol Monad do
  @moduledoc """
  Monad is an `Applicative` (=> `Functor`) that defines `flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var`.

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

  ## Monad ##

  @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
  def flat_map(tx, f)
end

defimpl Monad, for: List do
  @type t(x) :: [x]

  @spec map([x], (x -> y)) :: [y] when x: var, y: var
  defdelegate map(tx, f), to: Functor

  @spec pure(x) :: [x] when x: var
  defdelegate pure(x), to: Applicative

  @spec ap([(x -> y)], [x]) :: [y] when x: var, y: var
  defdelegate ap(tf, tx), to: Applicative

  @spec product([x], [y]) :: [{x, y}] when x: var, y: var
  defdelegate product(tx, ty), to: Applicative

  @spec flat_map([x], (x -> [y])) :: [y] when x: var, y: var
  def flat_map(tx, f), do: _flat_map(tx, f, [])

  @spec _flat_map([x], (x -> [y]), [y]) :: [y] when x: var, y: var
  defp _flat_map(tx, f, acc)
  defp _flat_map([], _, acc), do: acc
  defp _flat_map([h | t], f, acc), do: _flat_map(t, f, acc ++ f.(h))
end
