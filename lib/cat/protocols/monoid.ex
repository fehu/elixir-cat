defprotocol Cat.Monoid do
  @moduledoc """
  Monoid defines zero(t()) :: t()`.

  **It must also be `Semigroup`.**

  Module provides implementations for:
    * `Number`, `Integer`, `Float`
    * `List`
    * `Stream`
  """

  @spec zero(t()) :: t()
  def zero(example)
end

alias Cat.Monoid

# Only `:additive`
defimpl Monoid, for: [Integer, Float, Number] do
  @spec zero(number()) :: number()
  def zero(_), do: 0
end

defimpl Monoid, for: List do
  @spec zero(list()) :: list()
  def zero(_), do: []
end

defimpl Monoid, for: Stream do
  @spec zero(Enumerable.t()) :: Enumerable.t()
  def zero(_), do: %Stream{}
end

