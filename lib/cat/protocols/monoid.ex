defprotocol Monoid do
  @moduledoc """
  Monoid is a `Semigroup` that defines `@spec zero(module()) :: t()`.

  Module provides implementations for:
    * `Number`, `Integer`, `Float`
    * `List`
    * `Stream`
  """

  @spec combine(t(), t()) :: t()
  def combine(x, y)

  @spec zero(t()) :: t()
  def zero(_x)
end

# Only `:additive`
defimpl Monoid, for: [Integer, Float, Number] do
  @spec combine(number(), number()) :: number()
  def combine(x, y), do: Semigroup.Number.combine(:additive, x, y)

  @spec zero(number()) :: number()
  def zero(_), do: 0
end

defimpl Monoid, for: List do
  @spec combine(list(), list()) :: list()
  defdelegate combine(x, y), to: Semigroup

  @spec zero(list()) :: list()
  def zero(_), do: []
end

defimpl Monoid, for: Stream do
  @spec combine(Enumerable.t(), Enumerable.t()) :: Enumerable.t()
  defdelegate combine(x, y), to: Semigroup

  @spec zero(Enumerable.t()) :: Enumerable.t()
  def zero(_), do: %Stream{}
end

