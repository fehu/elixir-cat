defprotocol Cat.MonadError do
  @moduledoc """
  MonadError defines
    * `raise(t(any), error) :: t(none)`
    * `recover(t(a), (error -> t(a))) :: t(a)`
    * `lift_ok_or_error(t(any), ok_or_error(a)) :: t(a)`
    * `attempt(t(a)) :: t(ok_or_error(a))`

  **It must also be `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `MonadError.Default`):
    * `lift_ok_or_error(t(any), ok_or_error(a)) :: t(a)`
    * `attempt(t(a)) :: t(ok_or_error(a))`
  """

  @type t(_x) :: term

  @spec raise(t(any), error) :: t(none) when error: any
  def raise(example, error)

  @spec recover(t(a), (error -> t(a))) :: t(a) when a: var, error: any
  def recover(ta, f)

  @spec on_error(t(a), (error -> t(no_return) | no_return)) :: t(a) when a: var, error: any
  def on_error(ta, f)

  @type ok_or_error(a) :: {:ok, a} | {:error, any}

  @spec lift_ok_or_error(t(any), ok_or_error(a)) :: t(a) when a: var
  def lift_ok_or_error(example, result)

  @spec attempt(t(a)) :: t(ok_or_error(a)) when a: var
  def attempt(ta)
end

alias Cat.{Functor, MonadError}

defmodule Cat.MonadError.Default do
  @spec on_error(MonadError.t(a), (error -> MonadError.t(no_return))) :: MonadError.t(a) when a: var, error: any
  def on_error(ta, f), do:
    MonadError.recover ta, fn error ->
      Functor.as f.(error), MonadError.raise(ta, error)
    end

  @spec attempt(MonadError.t(a)) :: MonadError.t(MonadError.ok_or_error(a)) when a: var
  def attempt(ta), do:
    MonadError.recover(
      Functor.map(ta, &({:ok, &1})),
      &({:error, &1})
    )
end

defmodule Cat.MonadError.Arrow do
  @spec raise(error) :: (MonadError.t(any) -> MonadError.t(none)) when error: any
  def raise(example), do: &MonadError.raise(example, &1)

  @spec recover((error -> MonadError.t(a))) :: (MonadError.t(a) -> MonadError.t(a)) when a: var, error: any
  def recover(f), do: &MonadError.recover(&1, f)

  @spec on_error((error -> MonadError.t(no_return) | no_return)) :: (MonadError.t(a) -> MonadError.t(a)) when a: var, error: any
  def on_error(f), do: &MonadError.on_error(&1, f)

  @spec lift_ok_or_error(MonadError.t(any)) :: (MonadError.ok_or_error(a) -> MonadError.t(a)) when a: var
  def lift_ok_or_error(example), do: &MonadError.lift_ok_or_error(example, &1)
end
