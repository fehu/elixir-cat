defmodule Either do
  @moduledoc """
  Either `left` or `right`.

  Implements protocols:
    * `Functor`
    * `Applicative`
    * `Monad`
  """

  defmodule Left do
    @enforce_keys [:v]
    defstruct [:v]
  end

  defmodule Right do
    @enforce_keys [:v]
    defstruct [:v]
  end

  @type left(x) :: %Left{v: x}
  @type right(x) :: %Right{v: x}

  @type t(l, r) :: left(l) | right(r)

  @spec left(l) :: t(l, none) when l: var
  def left(l), do: %Left{v: l}

  @spec left?(t(any, any)) :: boolean
  def left?(%Left{}), do: true
  def left?(_), do: false

  @spec maybe_left(t(l, any)) :: Maybe.t(l) when l: var
  def maybe_left(%Left{v: l}), do: l
  def maybe_left(%Right{}), do: nil

  @spec right(r) :: t(none, r) when r: var
  def right(r), do: %Right{v: r}

  @spec right?(t(any, any)) :: boolean
  def right?(%Right{}), do: true
  def right?(_), do: false

  @spec maybe_right(t(any, r)) :: Maybe.t(r) when r: var
  def maybe_right(%Right{v: r}), do: r
  def maybe_right(%Left{}), do: nil

  @spec fold(t(l, r), (l -> x), (r -> x)) :: x when l: var, r: var, x: var
  def fold(%Left{v: l}, case_left, _), do: case_left.(l)
  def fold(%Right{v: r}, _, case_right), do: case_right.(r)

  @spec swap(t(l, r)) :: t(l, r) when l: var, r: var
  def swap(%Left{v: l}), do: %Right{v: l}
  def swap(%Right{v: r}), do: %Left{v: r}
end

alias Either.{Left, Right}

defimpl Functor, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(%Right{v: x}, f), do: %Right{v: f.(x)}
  def map(either, _), do: either
end

defimpl Applicative, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec pure(t(any), x) :: t(x) when x: var
  def pure(_, x), do: %Right{v: x}

  @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
  def ap(%Right{v: f}, %Right{v: x}), do: %Right{v: f.(x)}
  def ap(%Right{}, l=%Left{}), do: l
  def ap(l, _), do: l

  @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
  defdelegate product(tx, ty), to: Applicative.Default
end

defimpl Monad, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
  def flat_map(%Right{v: x}, f), do: f.(x)
  def flat_map(l=%Left{}, _), do: l
end

defimpl MonadError, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec raise(t(any), any) :: t(none)
  def raise(_, error), do: %Left{v: error}

  @spec recover(t(x), (any -> t(x))) :: t(x) when x: var
  def recover(%Left{v: error}, f), do: f.(error)
  def recover(right, _), do: right
end
