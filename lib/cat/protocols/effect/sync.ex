defprotocol Cat.Effect.Sync do
  @moduledoc """
  Suspends synchronous side effects.

  Sync defines
    * `defer((-> t(x))) :: t(x)`
    * `delay(t(any), (-> x)) :: t(x)`

  **It must also be `Bracket`, `MonadError, `Monad`, `Applicative` and `Functor`.**
  """

  @type t(_x) :: term

  @spec defer((-> t(x))) :: t(x) when x: var
  def defer(txf)

  @spec delay(t(any), (-> x)) :: t(x) when x: var
  def delay(example, xf)
end

alias Cat.Effect.Sync

defmodule Cat.Effect.Sync.Arrow do
  @spec delay(Sync.t(any)) :: ((-> x) -> Sync.t(x)) when x: var
  def delay(example), do: &Sync.delay(example, &1)
end
