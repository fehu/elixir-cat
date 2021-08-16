defprotocol Cat.MonadError do
  @moduledoc """
  MonadError defines
    * `raise(t(any), error) :: t(none)`
    * `recover(t(x), (error -> t(x))) :: t(x)`
    * `lift_ok_or_error(t(any), ok_or_error(x)) :: t(x)`
    * `attempt(t(x)) :: t(ok_or_error(x))`

  **It must also be `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `MonadError.Default`):
    * `lift_ok_or_error(t(any), ok_or_error(x)) :: t(x)`
    * `attempt(t(x)) :: t(ok_or_error(x))`
  """

  @type t(_x) :: term

  @spec raise(t(any), error) :: t(none) when error: any
  def raise(example, error)

  @spec recover(t(x), (error -> t(x))) :: t(x) when x: var, error: any
  def recover(tx, f)

  @type ok_or_error(x) :: {:ok, x} | {:error, any}

  @spec lift_ok_or_error(t(any), ok_or_error(x)) :: t(x) when x: var
  def lift_ok_or_error(example, result)

  @spec attempt(t(x)) :: t(ok_or_error(x)) when x: var
  def attempt(tx)
end

alias Cat.{Functor, MonadError}

defmodule Cat.MonadError.Default do
  @spec attempt(MonadError.t(x)) :: MonadError.t(MonadError.ok_or_error(x)) when x: var
  def attempt(tx), do:
    MonadError.recover(
      Functor.map(tx, &({:ok, &1})),
      &({:error, &1})
    )
end

defmodule Cat.MonadError.Arrow do
  @spec raise(error) :: (MonadError.t(any) -> MonadError.t(none)) when error: any
  def raise(example), do: &MonadError.raise(example, &1)

  @spec recover((error -> MonadError.t(x))) :: (MonadError.t(x) -> MonadError.t(x)) when x: var, error: any
  def recover(f), do: &MonadError.recover(&1, f)

  @spec lift_ok_or_error(MonadError.t(any)) :: (MonadError.ok_or_error(x) -> MonadError.t(x)) when x: var
  def lift_ok_or_error(example), do: &MonadError.lift_ok_or_error(example, &1)
end
