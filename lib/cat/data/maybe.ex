# TODO: rewrite not to depend on `nil`
defmodule Maybe do
  @moduledoc """
    A value or nil.

    Implements protocols:
      * `Functor`
      * `Applicative`
      * `Monad`
  """

  @opaque t(x) :: x | nil

  @spec new(x | nil) :: t(x) when x: var
  def new(x), do: x

  @spec of(x) :: t(x) when x: var
  def of(x), do: x

  @spec empty() :: t(none())
  def empty(), do: nil

  @spec defined?(t(any)) :: boolean
  def defined?(nil), do: false
  def defined?(_), do: true

  @spec empty?(t(any)) :: boolean
  def empty?(nil), do: true
  def empty?(_), do: false

  @spec get(t(x)) :: x when x: var
  def get(maybe) when maybe != nil , do: maybe

  #############################################
  ########## PROTOCOL IMPLEMENTATIONS #########
  #############################################

  defimpl Functor, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
    def map(nil, _), do: nil
    def map(x, f),   do: f.(x)
  end

  defimpl Applicative, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec pure(t(any), x) :: t(x) when x: var
    def pure(_, x), do: Maybe.of(x)

    @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
    def ap(nil, _), do: nil
    def ap(_, nil), do: nil
    def ap(f, x),   do: f.(x)

    @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
    defdelegate product(tx, ty), to: Applicative.Default
  end

  defimpl Monad, for: Maybe do
    @type t(x) :: Maybe.t(x)

    @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
    def flat_map(nil, _), do: nil
    def flat_map(x, f),   do: f.(x)
  end

end
