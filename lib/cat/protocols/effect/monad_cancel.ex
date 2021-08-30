defprotocol Cat.Effect.MonadCancel do
  @moduledoc """
  MonadCancel defines
    * `uncancelable((poll -> t(a))) :: t(a)`
    * `canceled(t(any)) :: t(none)`
    * `on_cancel(t(a), t(no_return)) :: t(a)`
    * `bracket((poll -> t(a)), (a -> t(b)), (a, outcome(b) -> t(no_return))) :: t(b)`
    * `guarantee(t(a), (outcome(a) -> t(no_return))) :: t(a)`

  **It must also be `MonadError, `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `MonadCancel.Default`):
    * `bracket((poll -> t(a)), (a -> t(b)), (a, outcome(b) -> t(no_return))) :: t(b)`
    * `guarantee(t(a), (outcome(a) -> t(no_return))) :: t(a)`
  """

  @type t(_x) :: term

  @type poll :: (t(any) -> t(any))

  @type outcome(a) :: {:ok, a} | {:error, any} | :canceled

  @spec uncancelable((poll -> t(a))) :: t(a) when a: var
  def uncancelable(txf)

  @spec canceled(t(any)) :: t(none)
  def canceled(example)

  @spec on_cancel(t(a), t(no_return)) :: t(a) when a: var
  def on_cancel(ta, finalizer)

  @spec bracket((poll -> t(a)), (a -> t(b)), (a, outcome(b) -> t(no_return) | no_return)) :: t(b) when a: var, b: var
  def bracket(acquire, use, release)

  @spec guarantee(t(a), (outcome(a) -> t(no_return) | no_return)) :: t(a) when a: var
  def guarantee(ta, finalizer)
end

alias Cat.{Applicative, Monad, MonadError}
alias Cat.Effect.MonadCancel
alias Cat.Fun

require Fun

defmodule Cat.Effect.MonadCancel.Arrow do
  @type use(a, b) :: (a -> MonadCancel.t(b))

  @spec bracket(
          acquire: MonadCancel.t(a),
          release: (MonadCancel.exit_case(a) -> MonadCancel.t(no_return))
        ) :: (use(a, b) -> MonadCancel.t(b)) when a: var, b: var
  def bracket(acquire: acquire, release: release), do: &MonadCancel.bracket(acquire, &1, release)

  @spec guarantee(MonadCancel.t(no_return)) :: (MonadCancel.t(a) -> MonadCancel.t(a)) when a: var
  def guarantee(finalizer), do: &MonadCancel.guarantee(&1, finalizer)

  @spec on_cancel(MonadCancel.t(no_return)) :: (MonadCancel.t(a) -> MonadCancel.t(a)) when a: var
  def on_cancel(finalizer), do: &MonadCancel.on_cancel(&1, finalizer)
end

defmodule Cat.Effect.MonadCancel.Default do
  @spec bracket(
          acquire :: (MonadCancel.poll -> MonadCancel.t(a)),
          use :: (a -> MonadCancel.t(b)),
          release :: (a, MonadCancel.outcome(b) -> MonadCancel.t(no_return) | no_return)
        ) :: MonadCancel.t(b) when a: var, b: var
  def bracket(acquire, use, release) do
    MonadCancel.uncancelable fn poll ->
      Monad.flat_map acquire.(poll), fn a ->
        # TODO
        # we need to lazily evaluate `use` so that uncaught exceptions are caught within the effect
        # runtime, otherwise we'll throw here and the error handler will never be registered
        MonadCancel.guarantee(poll.(use.(a)), &release.(a, &1))
      end
    end
  end

  @spec guarantee(MonadCancel.t(a), (MonadCancel.outcome(a) -> MonadCancel.t(no_return) | no_return)) :: MonadCancel.t(a) when a: var
  def guarantee(ta, fin) do
    MonadCancel.uncancelable fn poll ->
      finalized = MonadCancel.on_cancel(poll.(ta), fin.(:canceled))
      handled = MonadError.on_error finalized, fn error ->
        MonadError.recover(fin.({:error, error}), Fun.const_inline(Fun.no_return))
      end
      Monad.flat_tap handled, fn a ->
        fin.({:ok, Applicative.pure(ta, a)})
      end
    end
  end

end
