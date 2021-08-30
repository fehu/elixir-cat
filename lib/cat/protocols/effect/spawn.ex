defprotocol Cat.Effect.Spawn do
  @moduledoc """

  Spawn defines
    * `start(t(a)) :: t(Fiber.t(t, a))`
    * `never(t(any)) :: t(none)`
    * `cede(t(any)) :: t(no_return)`
    * `background(t(a)) :: Resource.t(t, t(MonadCancel.outcome(a)))`
    * `race_pair(t(a), t(b)) :: t(race_pair_out(a, b))`
    * `race(t(a), t(b)) :: t(Either.t(a, b))`
    * `both(t(a), t(b)) :: t({a, b})`

  **It must also be `MonadCancel`, `MonadError, `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `Spawn.Default`):
    * `background(t(a)) :: Resource.t(t, t(MonadCancel.outcome(a)))`
    * `race(t(a), t(b)) :: t(Either.t(a, b))`
    * `both(t(a), t(b)) :: t({a, b})`
  """

  @type t(_x) :: term

  @spec start(t(a)) :: t(Fiber.t(t, a)) when a: var
  def start(ta)

  @spec never(t(any)) :: t(none)
  def never(example)

  @spec cede(t(any)) :: t(no_return)
  def cede(example)

  @spec background(t(a)) :: Resource.t(t, t(MonadCancel.outcome(a))) when a: var
  def background(ta)

  @typep race_pair_out(a, b) :: Either.t(
                                  {MonadCancel.outcome(a), Fiber.t(b)},
                                  {Fiber.t(a), MonadCancel.outcome(b)}
                                )
  @spec race_pair(t(a), t(b)) :: t(race_pair_out(a, b)) when a: var, b: var
  def race_pair(ta, tb)

  @spec race(t(a), t(b)) :: t(Either.t(a, b)) when a: var, b: var
  def race(ta, tb)

  @spec both(t(a), t(b)) :: t({a, b}) when a: var, b: var
  def both(ta, tb)

end

alias Cat.{Applicative, Either, Monad, MonadError}
alias Cat.Effect.{Fiber, MonadCancel, Resource, Spawn}

defmodule Cat.Effect.Spawn.Default do
  @spec background(Spawn.t(a)) :: Resource.t(Spawn.t, Spawn.t(MonadCancel.outcome(a))) when a: var
  def background(ta) do
    Resource.new acquire: Spawn.start(ta),
                 release: &Fiber.cancel/1,
                 map: &Fiber.join/1
  end

  @spec race(Spawn.t(a), Spawn.t(b)) :: Spawn.t(Either.t(a, b)) when a: var, b: var
  def race(ta, tb) do
    MonadCancel.uncancelable fn poll ->
      Monad.flat_map poll.(Spawn.race_pair(ta, tb)), fn
        %Either.Left{v: {{:ok, a}, fb}} ->
          Applicative.product_r Fiber.cancel(fb), Functor.map(ta, &Either.left/1)
        %Either.Left{v: {{:error, error}, fb}} ->
          Applicative.product_r Fiber.cancel(fb), MonadError.raise(ta, error)
        %Either.Left{v: {:canceled, fb}} ->
          joined = MonadCancel.on_cancel(poll.(Fiber.join(fb)), Fiber.cancel(fb))
          Monad.flat_map joined, fn
            {:ok, _}        -> Functor.map(tb, &Either.right/1)
            {:error, error} -> MonadError.raise(tb, error)
            :canceled       -> Applicative.product_r poll.(MonadCancel.canceled(tb)), Spawn.never(tb)
          end
        %Either.Right{v: {fa, {:ok, b}}} ->
          Applicative.product_r Fiber.cancel(fa), Functor.map(tb, &Either.right/1)
        %Either.Right{v: {fa, {:error, error}}} ->
          Applicative.product_r Fiber.cancel(fa), MonadError.raise(tb, error)
        %Either.Right{v: {fa, :canceled}} ->
          joined = MonadCancel.on_cancel(poll.(Fiber.join(fa)), Fiber.cancel(fa))
          Monad.flat_map joined, fn
            {:ok, _}        -> Functor.map(ta, &Either.right/1)
            {:error, error} -> MonadError.raise(ta, error)
            :canceled       -> Applicative.product_r poll.(MonadCancel.canceled(ta)), Spawn.never(ta)
          end
      end
    end
  end

  @spec both(Spawn.t(a), Spawn.t(b)) :: Spawn.t({a, b}) when a: var, b: var
  def both(ta, tb) do
    MonadCancel.uncancelable fn poll ->
      Monad.flat_map poll.(Spawn.race_pair(ta, tb)), fn
        %Either.Left{v: {{:ok, a}, fb}} ->
          joined = MonadCancel.on_cancel(poll.(Fiber.join(fb)), Fiber.cancel(fb))
          Monad.flat_map joined, fn
            {:ok, b}        -> Applicative.pure(tb, {a, b})
            {:error, error} -> MonadError.raise(tb, error)
            :canceled       -> Applicative.product_r poll.(MonadCancel.canceled(tb)), Spawn.never(tb)
          end
        %Either.Left{v: {{:error, error}, fb}} ->
          Applicative.product_r Fiber.cancel(fb), MonadError.raise(tb, error)
        %Either.Left{v: {:canceled, fb}} ->
          Applicative.product_r poll.(MonadCancel.canceled(tb)), Spawn.never(tb)
        %Either.Right{v: {fa, {:ok, b}}} ->
          joined = MonadCancel.on_cancel(poll.(Fiber.join(fa)), Fiber.cancel(fa))
          Monad.flat_map joined, fn
            {:ok, a}        -> Applicative.pure(ta, {a, b})
            {:error, error} -> MonadError.raise(ta, error)
            :canceled       -> Applicative.product_r poll.(MonadCancel.canceled(ta)), Spawn.never(ta)
          end
        %Either.Right{v: {fa, {:error, error}}} ->
          Applicative.product_r Fiber.cancel(fa), MonadError.raise(ta, error)
        %Either.Right{v: {fa, :canceled}} ->
          Applicative.product_r poll.(MonadCancel.canceled(ta)), Spawn.never(ta)
      end
    end
  end

end