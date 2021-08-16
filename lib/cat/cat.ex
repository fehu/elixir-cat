defmodule Cat do
  @moduledoc """
    Inspired by [cats](https://github.com/typelevel/cats) and [cats-effect (2)](https://github.com/typelevel/cats-effect)
  """

  # # Data # #
  alias Cat.{Either, Maybe}

  @type maybe(x) :: Maybe.t(x)
  @type either(l, r) :: Either.t(l, r)

  # # Protocols # #

  alias Cat.{Functor, Applicative, Monad, MonadError}
  alias Cat.{Semigroup, Monoid, Foldable, Reducible}

  ## Delegates to protocols ##

  # Functor

  @spec map(Functor.t(x), (x -> y)) :: Functor.t(y) when x: var, y: var
  defdelegate map(tx, f), to: Functor

  @spec as(Functor.t(any), x) :: Functor.t(x) when x: var
  defdelegate as(t, x), to: Functor

  # Applicative

  @spec pure(Applicative.t(any), x) :: Applicative.t(x) when x: var
  defdelegate pure(example, x), to: Applicative

  @spec ap(Applicative.t((x -> y)), Applicative.t(x)) :: Applicative.t(y) when x: var, y: var
  defdelegate ap(tf, tx), to: Applicative

  @spec product(Applicative.t(x), Applicative.t(y)) :: Applicative.t({x, y}) when x: var, y: var
  defdelegate product(tx, ty), to: Applicative

  # Monad

  @spec flat_map(Monad.t(x), (x -> Monad.t(y))) :: Monad.t(y) when x: var, y: var
  defdelegate flat_map(tx, f), to: Monad

  # MonadError

  @spec raise(MonadError.t(any), error) :: MonadError.t(none) when error: any
  defdelegate raise(example, error), to: MonadError

  @spec recover(MonadError.t(x), (error -> MonadError.t(x))) :: MonadError.t(x) when x: var, error: any
  defdelegate recover(tx, f), to: MonadError

  @spec lift_ok_or_error(MonadError.t(any), MonadError.ok_or_error(x)) :: MonadError.t(x) when x: var
  defdelegate lift_ok_or_error(example, result), to: MonadError

  @spec attempt(MonadError.t(x)) :: MonadError.t(MonadError.ok_or_error(x)) when x: var
  defdelegate attempt(tx), to: MonadError

  # Semigroup

  @spec combine(Semigroup.t(), Semigroup.t()) :: Semigroup.t()
  defdelegate combine(x, y), to: Semigroup

  # Monoid

  @spec zero(Monoid.t()) :: Monoid.t()
  defdelegate zero(example), to: Monoid

  # Foldable

  @spec fold_left(Foldable.t(x), y, (y, x -> y)) :: y when x: var, y: var
  defdelegate fold_left(tx, zero, f), to: Foldable

  # Reducible

  @spec reduce_left(Reducible.t(x), (x, x -> x)) :: x when x: var
  defdelegate reduce_left(tx, f), to: Reducible

  ## Delegates to protocols' arrows

  defmodule Arrow do
    # Functor

    @spec map((x -> y)) :: (Functor.t(x) -> Functor.t(y)) when x: var, y: var
    defdelegate map(f), to: Functor.Arrow

    @spec as(Functor.t(any)) :: (x -> Functor.t(x)) when x: var
    defdelegate as(t), to: Functor.Arrow

    # Applicative

    @spec pure(Applicative.t(any)) :: (x -> Applicative.t(x)) when x: var
    defdelegate pure(example), to: Applicative.Arrow

    @spec ap(Applicative.t((x -> y))) :: (Applicative.t(x) -> Applicative.t(y))when x: var, y: var
    defdelegate ap(tf), to: Applicative.Arrow

    # Monad

    @spec flat_map((x -> Monad.t(y))) :: (Monad.t(x) -> Monad.t(y)) when x: var, y: var
    defdelegate flat_map(f), to: Monad.Arrow

    # MonadError

    @spec raise(error) :: (MonadError.t(any) -> MonadError.t(none)) when error: any
    defdelegate raise(example), to: MonadError.Arrow

    @spec recover((error -> MonadError.t(x))) :: (MonadError.t(x) -> MonadError.t(x)) when x: var, error: any
    defdelegate recover(tx), to: MonadError.Arrow

    @spec lift_ok_or_error(MonadError.t(any)) :: (MonadError.ok_or_error(x) -> MonadError.t(x)) when x: var
    defdelegate lift_ok_or_error(example), to: MonadError.Arrow
  end


  # # Effect # #

  defmodule Effect do

    alias Cat.Effect.{Async, Bracket, Sync}

    ## Delegates to protocols ##

    # Bracket

    @spec bracket(
            acquire: Bracket.t(x),
            use: (x -> Bracket.t(y)),
            release: (Bracket.exit_case(x) -> Bracket.t(no_return))
          ) :: Bracket.t(y) when x: var, y: var
    def bracket(acquire: acquire, use: use, release: release), do:
      Bracket.bracket(acquire, use, release)

    @spec guarantee(Bracket.t(x), finalize: Bracket.t(no_return)) :: Bracket.t(x) when x: var
    def guarantee(tx, finalize: finalizer), do:
      Bracket.guarantee(tx, finalizer)

    @spec uncancelable(Bracket.t(x)) :: Bracket.t(x) when x: var
    defdelegate uncancelable(tx), to: Bracket

    # Sync

    @spec defer((-> Sync.t(x))) :: Sync.t(x) when x: var
    defdelegate defer(txf), to: Sync

    @spec delay(Sync.t(any), (-> x)) :: Sync.t(x) when x: var
    defdelegate delay(example, xf), to: Sync

    # Async

    @spec async(Async.t(any), (Async.callback(x) -> Async.t(no_return) | no_return)) :: Async.t(x) when x: var
    defdelegate async(example, fun), to: Async

    @spec async_effect(Async.t(x), (Bracket.exit_case(x) -> Async.t(no_return))) :: Async.t(no_return) when x: var
    defdelegate async_effect(effect, on_complete), to: Async
    
    @spec never(Async.t(any)) :: Async.t(none)
    defdelegate never(example), to: Async

    ## Delegates to protocols' arrows

    defmodule Arrow do
      # Bracket

      @spec bracket(
              acquire: Bracket.t(x),
              release: (Bracket.exit_case(x) -> Bracket.t(no_return))
            ) :: (Bracket.Arrow.use(x, y) -> Bracket.t(y)) when x: var, y: var
      def bracket(acquire: acquire, release: release), do: Bracket.Arrow.bracket(acquire: acquire, release: release)

      @spec guarantee(Bracket.t(no_return)) :: (Bracket.t(x) -> Bracket.t(x)) when x: var
      defdelegate guarantee(finalizer), to: Bracket.Arrow

      # Sync

      @spec delay(Sync.t(any)) :: ((-> x) -> Sync.t(x)) when x: var
      defdelegate delay(example), to: Sync.Arrow

      # Async

      @spec async(Async.t(any)) :: ((Async.callback(x) -> Async.t(no_return) | no_return) -> Async.t(x)) when x: var
      defdelegate async(example), to: Async.Arrow

      @spec async_effect((Bracket.exit_case(x) -> Async.t(no_return))) :: (Async.t(x) -> Async.t(no_return)) when x: var
      defdelegate async_effect(on_complete), to: Async.Arrow
    end
  end

end
