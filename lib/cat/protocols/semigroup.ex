defprotocol Cat.Semigroup do
  @moduledoc """
  Semigroup defines a sum `combine(t(), t()) :: t()`.

  Module provides implementations for:
    * `Number`, `Integer`, `Float`
    * `List`
    * `Stream`
  """

  @spec combine(t(), t()) :: t()
  def combine(a, b)

end

alias Cat.Semigroup

defimpl Semigroup, for: [Integer, Float, Number] do
  @spec combine(number(), number()) :: number()
  def combine(a, b), do: combine(:additive, a, b)

  @type op() :: :additive | :multiplicative

  @spec combine(op :: op(), number(), number()) :: number()
  def combine(:additive, a, b), do: a + b
  def combine(:multiplicative, a, b), do: a * b
end

defimpl Semigroup, for: List do
  @spec combine(list(), list()) :: list()
  def combine(a, b), do: a ++ b
end

defimpl Semigroup, for: Stream do
  @spec combine(Enumerable.t(), Enumerable.t()) :: Enumerable.t()
  def combine(a, b), do: Stream.concat(a, b)
end
