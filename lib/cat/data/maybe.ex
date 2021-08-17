# TODO: rewrite not to depend on `nil`
defmodule Cat.Maybe do
  @moduledoc """
    A value or nil.

    Implements protocols:
      * `Functor`
      * `Applicative`
      * `Monad`
  """

  defmodule Just do
    @enforce_keys [:val]
    defstruct [:val]
  end

  defmodule Nothing do
    defstruct []
  end

  @type just(a) :: %Just{val: a}
  @type nothing :: %Nothing{}

  @type t(a) :: just(a) | nothing

  @spec new(a | nil) :: t(a) when a: var
  def new(nil), do: %Nothing{}
  def new(a), do: %Just{val: a}

  @spec of(a) :: t(a) when a: var
  def of(a), do: %Just{val: a}

  @spec empty() :: t(none())
  def empty(), do: %Nothing{}

  @spec defined?(t(any)) :: boolean
  def defined?(%Nothing{}), do: false
  def defined?(_), do: true

  @spec empty?(t(any)) :: boolean
  def empty?(%Nothing{}), do: true
  def empty?(_), do: false

  @spec get(t(a)) :: a when a: var
  def get(%Just{val: val}), do: val

  @spec sample() :: t(none)
  def sample(), do: %Nothing{}

  #############################################
  ########## PROTOCOL IMPLEMENTATIONS #########
  #############################################

  alias Cat.Maybe
  alias Cat.Maybe.{Just, Nothing}

  defimpl Cat.Functor, for: [Maybe, Just, Nothing] do
    @type t(a) :: Maybe.t(a)

    @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
    def map(%Nothing{}, _), do: %Nothing{}
    def map(%Just{val: a}, f), do: %Just{val: f.(a)}

    @spec as(t(any), a) :: t(a) when a: var
    defdelegate as(t, a), to: Cat.Functor.Default
  end

  defimpl Cat.Applicative, for: [Maybe, Just, Nothing] do
    @type t(a) :: Maybe.t(a)

    @spec pure(t(any), a) :: t(a) when a: var
    def pure(_, a), do: %Just{val: a}

    @spec ap(t((a -> b)), t(a)) :: t(b) when a: var, b: var
    def ap(%Nothing{}, _), do: %Nothing{}
    def ap(_, %Nothing{}), do: %Nothing{}
    def ap(f, %Just{val: a}), do: f.(a)

    @spec product(t(a), t(b)) :: t({a, b}) when a: var, b: var
    defdelegate product(ta, tb), to: Cat.Applicative.Default
  end

  defimpl Cat.Monad, for: [Maybe, Just, Nothing] do
    @type t(a) :: Maybe.t(a)

    @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: var, b: var
    def flat_map(%Nothing{}, _), do: %Nothing{}
    def flat_map(%Just{val: a}, f),   do: f.(a)

    @spec flat_tap(Maybe.t(a), (a -> Maybe.t(no_return))) :: Maybe.t(a) when a: var
    defdelegate flat_tap(ta, f), to: Cat.Monad.Default
  end

end
