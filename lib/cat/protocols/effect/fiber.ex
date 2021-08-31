defprotocol Cat.Effect.Fiber do
  @moduledoc false

  @type t(_x) :: any
  @type f(_x) :: any

  @spec cancel(t(any)) :: f(no_return)
  def cancel(ta)

  @spec join(t(a)) :: f(MonadCancel.outcome(a)) when a: var
  def join(ta)
end
