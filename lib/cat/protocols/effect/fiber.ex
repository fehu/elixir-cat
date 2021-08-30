defprotocol Cat.Effect.Fiber do
  @moduledoc false

  @type t(_x) :: term

  @spec cancel(t(any)) :: t(no_return)
  def cancel(ta)

  @spec join(t(a)) :: t(MonadCancel.outcome(a)) when a: var
  def join(ta)
end
