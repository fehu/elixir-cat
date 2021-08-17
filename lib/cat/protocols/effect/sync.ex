defprotocol Cat.Effect.Sync do
  @moduledoc """
  Suspends synchronous side effects.

  Sync defines
    * `defer((-> t(a))) :: t(a)`
    * `delay(t(any), (-> a)) :: t(a)`

  **It must also be `Bracket`, `MonadError, `Monad`, `Applicative` and `Functor`.**
  """

  @type t(_x) :: term

  @spec defer((-> t(a))) :: t(a) when a: var
  def defer(taf)

  @spec delay(t(any), (-> a)) :: t(a) when a: var
  def delay(example, xf)
end

alias Cat.Effect.Sync

defmodule Cat.Effect.Sync.Arrow do
  @spec delay(Sync.t(any)) :: ((-> a) -> Sync.t(a)) when a: var
  def delay(example), do: &Sync.delay(example, &1)
end
