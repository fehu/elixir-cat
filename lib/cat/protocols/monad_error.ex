defprotocol MonadError do
  @moduledoc """
  MonadError defines
    * `raise(t(any), error) :: t(none)`
    * `recover(t(x), (error -> t(x))) :: t(x)`

  **It must also be `Monad`, `Applicative` and `Functor`.**
  """

  @type t(_x) :: term

  @spec raise(t(any), error) :: t(none) when error: any
  def raise(example, error)

  @spec recover(t(x), (error -> t(x))) :: t(x) when x: var, error: any
  def recover(tx, f)

end

defmodule MonadError.Arrow do
  @spec raise(error) :: (MonadError.t(any) -> MonadError.t(none)) when error: any
  def raise(example), do: &MonadError.raise(example, &1)

  @spec recover((error -> MonadError.t(x))) :: (MonadError.t(x) -> MonadError.t(x)) when x: var, error: any
  def recover(f), do: &MonadError.recover(&1, f)
end
