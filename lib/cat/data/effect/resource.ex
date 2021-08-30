defmodule Cat.Effect.Resource do
  @moduledoc false

  # Denotes type `f(a)`
  @typep ap(f, _a) :: f

  @enforce_keys [:acquire, :release]
  defstruct [:acquire, :release, :map]
  @type t(f, x0, x) :: %__MODULE__{acquire: ap(f, x0), release: (x0 -> ap(f, no_return)), map: (x0 -> x)}
  @type t(f, x) :: t(f, any, x)

  @spec new(acquire: ap(f, x), release: (x -> ap(f, no_return))) :: t(f, x) when f: var, x: var
  def new(acquire: acquire, release: release), do:
    %__MODULE__{acquire: acquire, release: release}

  @spec new(acquire: ap(f, x0), release: (x0 -> ap(f, no_return)), map: (x0 -> x)) :: t(f, x) when f: var, x0: var, x: var
  def new(acquire: acquire, release: release, map: map), do:
    %__MODULE__{acquire: acquire, release: release, map: map}

end

# TODO: protocols


