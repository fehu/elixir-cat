# TODO: rewrite not to depend on `nil`
defmodule Maybe do
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

  @type just(x) :: %Just{val: x}
  @type nothing :: %Nothing{}

  @type t(x) :: just(x) | nothing

  @spec new(x | nil) :: t(x) when x: var
  def new(nil), do: %Nothing{}
  def new(x), do: %Just{val: x}

  @spec of(x) :: t(x) when x: var
  def of(x), do: %Just{val: x}

  @spec empty() :: t(none())
  def empty(), do: %Nothing{}

  @spec defined?(t(any)) :: boolean
  def defined?(%Nothing{}), do: false
  def defined?(_), do: true

  @spec empty?(t(any)) :: boolean
  def empty?(%Nothing{}), do: true
  def empty?(_), do: false

  @spec get(t(x)) :: x when x: var
  def get(%Just{val: val}), do: val

  #############################################
  ########## PROTOCOL IMPLEMENTATIONS #########
  #############################################

  defimpl Functor, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
    def map(%Nothing{}, _), do: %Nothing{}
    def map(%Just{val: x}, f), do: %Just{val: f.(x)}
  end

  defimpl Applicative, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec pure(t(any), x) :: t(x) when x: var
    def pure(_, x), do: %Just{val: x}

    @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
    def ap(%Nothing{}, _), do: %Nothing{}
    def ap(_, %Nothing{}), do: %Nothing{}
    def ap(f, %Just{val: x}), do: f.(x)

    @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
    defdelegate product(tx, ty), to: Applicative.Default
  end

  defimpl Monad, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
    def flat_map(%Nothing{}, _), do: %Nothing{}
    def flat_map(%Just{val: x}, f),   do: f.(x)
  end

end
