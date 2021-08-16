defprotocol Cat.Functor do
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

  @spec as(t(any), x) :: t(x) when x: var
  def as(t, x)
end

alias Cat.Functor

defmodule Cat.Functor.Arrow do
  @spec map((x -> y)) :: (Functor.t(x) -> Functor.t(y)) when x: var, y: var
  def map(f), do: &Functor.map(&1, f)

  @spec as(Functor.t(any)) :: (x -> Functor.t(x)) when x: var
  def as(t), do: &Functor.as(t, &1)
end

defmodule Cat.Functor.Default do
  @spec as(Functor.t(any), x) :: Functor.t(x) when x: var
  def as(t, x), do: Functor.map t, fn _ -> x end
end

defimpl Functor, for: List do
  @type t(x) :: [x]

  @spec map([x], (x -> y)) :: [y] when x: var, y: var
  def map(xa, f), do: Enum.map(xa, f)

  @spec as([any], x) :: [x] when x: var
  defdelegate as(t, x), to: Cat.Functor.Default
end

defimpl Functor, for: Stream do
  @type t(_x) :: Enumerable.t()

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(xa, f), do: Stream.map(xa, f)

  @spec as(t(any), x) :: t(x) when x: var
  defdelegate as(t, x), to: Cat.Functor.Default
end

defimpl Functor, for: Map do
  @type t(x) :: %{optional(any) => x}

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(xa, f), do: Map.new(xa, fn {k, v} -> {k, f.(v)} end)

  @spec as(t(any), x) :: t(x) when x: var
  defdelegate as(t, x), to: Cat.Functor.Default
end
