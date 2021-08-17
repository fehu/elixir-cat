defprotocol Cat.Functor do
  @moduledoc """
  Functor defines `map(t(a), (a -> b)) :: t(b) when a: var, b: var`.

  Module provides implementations for:
    * `List`
    * `Stream`
    * `Map`
  """

  @type t(_x) :: term

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(ta, f)

  @spec as(t(any), a) :: t(a) when a: var
  def as(t, a)
end

alias Cat.Functor

defmodule Cat.Functor.Arrow do
  @spec map((a -> b)) :: (Functor.t(a) -> Functor.t(b)) when a: var, b: var
  def map(f), do: &Functor.map(&1, f)

  @spec as(Functor.t(any)) :: (a -> Functor.t(a)) when a: var
  def as(t), do: &Functor.as(t, &1)
end

defmodule Cat.Functor.Default do
  @spec as(Functor.t(any), a) :: Functor.t(a) when a: var
  def as(t, a), do: Functor.map t, fn _ -> a end
end

defimpl Functor, for: List do
  @type t(a) :: [a]

  @spec map([a], (a -> b)) :: [b] when a: var, b: var
  def map(xa, f), do: Enum.map(xa, f)

  @spec as([any], a) :: [a] when a: var
  defdelegate as(t, a), to: Cat.Functor.Default
end

defimpl Functor, for: Stream do
  @type t(_x) :: Enumerable.t()

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(xa, f), do: Stream.map(xa, f)

  @spec as(t(any), a) :: t(a) when a: var
  defdelegate as(t, a), to: Cat.Functor.Default
end

defimpl Functor, for: Map do
  @type t(a) :: %{optional(any) => a}

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(xa, f), do: Map.new(xa, fn {k, v} -> {k, f.(v)} end)

  @spec as(t(any), a) :: t(a) when a: var
  defdelegate as(t, a), to: Cat.Functor.Default
end
