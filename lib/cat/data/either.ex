defmodule Cat.Either do
  @moduledoc """
  Either `left` or `right`.

  Implements protocols:
    * `Functor`
    * `Applicative`
    * `Monad`
  """

  alias Cat.Maybe

  defmodule Left do
    @enforce_keys [:v]
    defstruct [:v]
  end

  defmodule Right do
    @enforce_keys [:v]
    defstruct [:v]
  end

  @type left(a) :: %Left{v: a}
  @type right(a) :: %Right{v: a}

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

  @spec fold(t(l, r), (l -> a), (r -> a)) :: a when l: var, r: var, a: var
  def fold(%Left{v: l}, case_left, _), do: case_left.(l)
  def fold(%Right{v: r}, _, case_right), do: case_right.(r)

  @spec swap(t(l, r)) :: t(l, r) when l: var, r: var
  def swap(%Left{v: l}), do: %Right{v: l}
  def swap(%Right{v: r}), do: %Left{v: r}

  @spec sample() :: t(:sample, none)
  def sample(), do: %Left{v: :sample}
end

alias Cat.Either
alias Cat.Either.{Left, Right}

defimpl Cat.Functor, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(%Right{v: a}, f), do: %Right{v: f.(a)}
  def map(either, _), do: either

  @spec as(t(any), a) :: t(a) when a: var
  defdelegate as(t, a), to: Cat.Functor.Default
end

defimpl Cat.Applicative, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec pure(t(any), a) :: t(a) when a: var
  def pure(_, a), do: %Right{v: a}

  @spec ap(t((a -> b)), t(a)) :: t(b) when a: var, b: var
  def ap(%Right{v: f}, %Right{v: a}), do: %Right{v: f.(a)}
  def ap(%Right{}, l=%Left{}), do: l
  def ap(l, _), do: l

  @spec product(t(a), t(b)) :: t({a, b}) when a: var, b: var
  defdelegate product(ta, tb), to: Cat.Applicative.Default

  @spec product_l(t(a), t(any)) :: t(a) when a: var
  defdelegate product_l(ta, tb), to: Cat.Applicative.Default

  @spec product_r(t(any), t(b)) :: t(b) when b: var
  defdelegate product_r(ta, tb), to: Cat.Applicative.Default

  @spec map2(t(a), t(b), (a, b -> c)) :: t(c) when a: var, b: var, c: var
  defdelegate map2(ta, tb, f), to: Cat.Applicative.Default
end

defimpl Cat.Monad, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: var, b: var
  def flat_map(%Right{v: a}, f), do: f.(a)
  def flat_map(l=%Left{}, _), do: l

  @spec flat_tap(t(a), (a -> t(no_return))) :: t(a) when a: var
  defdelegate flat_tap(ta, f), to: Cat.Monad.Default

  @spec flatten(t(t(a))) :: t(a) when a: var
  defdelegate flatten(tta), to: Cat.Monad.Default
end

defimpl Cat.MonadError, for: [Either, Left, Right] do
  @type t(r) :: Either.t(any, r)

  @spec raise(t(any), any) :: t(none)
  def raise(_, error), do: %Left{v: error}

  @spec recover(t(a), (any -> t(a))) :: t(a) when a: var
  def recover(%Left{v: error}, f), do: f.(error)
  def recover(right, _), do: right

  @spec on_error(t(a), (error -> t(no_return))) :: t(a) when a: var, error: any
  defdelegate on_error(ta, f), to: Cat.MonadError.Default

  @spec lift_ok_or_error(t(any), Cat.MonadError.ok_or_error(a)) :: t(a) when a: var
  def lift_ok_or_error(_, {:ok, a}), do: %Right{v: a}
  def lift_ok_or_error(_, {:error, e}), do: %Left{v: e}

  @spec attempt(t(a)) :: t(Cat.MonadError.ok_or_error(a)) when a: var
  defdelegate attempt(ta), to: Cat.MonadError.Default
end
