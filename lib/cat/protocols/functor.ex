defprotocol Functor do
  @moduledoc """
  Functor defines `map(t(x), (x -> y)) :: t(y) when x: var, y: var`.

  Module provides implementations for:
    * `List`
    * `Stream`
    * `Map`
  """

  @type t(_x) :: term

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(tx, f)
end

defimpl Functor, for: List do
  @type t(x) :: [x]

  @spec map([x], (x -> y)) :: [y] when x: var, y: var
  def map(xa, f), do: Enum.map(xa, f)
end

defimpl Functor, for: Stream do
  @type t(_x) :: Enumerable.t()

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(xa, f), do: Stream.map(xa, f)
end

defimpl Functor, for: Map do
  @type t(x) :: %{optional(any) => x}

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(xa, f), do: Map.new(xa, fn {k, v} -> {k, f.(v)} end)
end
