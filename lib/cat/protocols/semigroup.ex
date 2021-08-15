defprotocol Cat.Semigroup do
  @moduledoc """
  Semigroup defines a sum `combine(t(), t()) :: t()`.

  Module provides implementations for:
    * `Number`, `Integer`, `Float`
    * `List`
    * `Stream`
  """

  @spec combine(t(), t()) :: t()
  def combine(x, y)

end

alias Cat.Semigroup

defimpl Semigroup, for: [Integer, Float, Number] do
  @spec combine(number(), number()) :: number()
  def combine(x, y), do: combine(:additive, x, y)

  @type op() :: :additive | :multiplicative

  @spec combine(op :: op(), number(), number()) :: number()
  def combine(:additive, x, y), do: x + y
  def combine(:multiplicative, x, y), do: x * y
end

defimpl Semigroup, for: List do
  @spec combine(list(), list()) :: list()
  def combine(x, y), do: x ++ y
end

defimpl Semigroup, for: Stream do
  @spec combine(Enumerable.t(), Enumerable.t()) :: Enumerable.t()
  def combine(x, y), do: Stream.concat(x, y)
end
