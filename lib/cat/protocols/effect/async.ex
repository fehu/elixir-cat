defprotocol Cat.Effect.Async do
  @moduledoc """
  Suspends asynchronous side effects.

  # TODO: Elixir's `spawn` & `pid`

  Async defines
    * `async(t(any), (callback(a) -> t(no_return) | no_return)) :: t(a)`
    * `async_effect(t(a), (Bracket.exit_case(a) -> t(no_return) | no_return)) :: t(no_return)`
    * `never(t(any)) :: t(none)`

  **It must also be `Sync`, `Bracket`, `MonadError, `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `Async.Default`):
    * `guarantee(t(a), always: t(no_return)) :: t(a)`
    * `async_effect(t(a), (Bracket.exit_case(a) -> t(no_return) | no_return)) :: t(no_return)`
  """

  alias Cat.MonadError
  alias Cat.Effect.Bracket

  @type t(_x) :: term

  @type callback(a) :: (MonadError.ok_or_error(a) -> no_return)

  @spec async(t(any), (callback(a) -> t(no_return) | no_return)) :: t(a) when a: var
  def async(example, fun)

  @spec async_effect(t(a), (Bracket.exit_case(a) -> t(no_return) | no_return)) :: t(no_return) when a: var
  def async_effect(effect, on_complete)

  @spec never(t(any)) :: t(none)
  def never(example)
end

alias Cat.{Functor, MonadError}
alias Cat.Effect.{Async, Bracket}
alias Cat.Fun

require Fun

defmodule Cat.Effect.Async.Arrow do
  @spec async(Async.t(any)) :: ((Async.callback(a) -> Async.t(no_return) | no_return) -> Async.t(a)) when a: var
  def async(example), do: &Async.async(example, &1)

  @spec async_effect((Bracket.exit_case(a) -> Async.t(no_return))) :: (Async.t(a) -> Async.t(no_return)) when a: var
  def async_effect(on_complete), do: &Async.async_effect(&1, on_complete)
end

defmodule Cat.Effect.Async.Default do
  @spec async_effect(Async.t(a), (Bracket.exit_case(a) -> Async.t(no_return))) :: Async.t(no_return) when a: var
  def async_effect(effect, on_complete) do
    Async.async effect, fn callback ->
      attempt = MonadError.attempt(Bracket.guarantee(effect, on_complete))
      Functor.map(attempt, callback)
    end
  end

  @spec never(Async.t(any)) :: Async.t(none)
  def never(example), do: Async.async(example, Fun.const_inline(:nothing))
end
