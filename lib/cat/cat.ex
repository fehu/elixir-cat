defmodule Cat do
  @moduledoc """
    Inspired by [cats](https://github.com/typelevel/cats) and [cats-effect (2)](https://github.com/typelevel/cats-effect)
  """

  # # Data # #
  alias Cat.{Either, Maybe}

  @type maybe(a) :: Maybe.t(a)
  @type either(l, r) :: Either.t(l, r)

  # # Protocols # #

  alias Cat.{Functor, Applicative, Monad, MonadError}
  alias Cat.{Semigroup, Monoid, Foldable, Reducible}

  ## Delegates to protocols ##

  # Functor

  @spec map(Functor.t(a), (a -> b)) :: Functor.t(b) when a: var, b: var
  defdelegate map(ta, f), to: Functor

  @spec as(Functor.t(any), a) :: Functor.t(a) when a: var
  defdelegate as(t, a), to: Functor

  # Applicative

  @spec pure(Applicative.t(any), a) :: Applicative.t(a) when a: var
  defdelegate pure(example, a), to: Applicative

  @spec ap(Applicative.t((a -> b)), Applicative.t(a)) :: Applicative.t(b) when a: var, b: var
  defdelegate ap(tf, ta), to: Applicative

  @spec product(Applicative.t(a), Applicative.t(b)) :: Applicative.t({a, b}) when a: var, b: var
  defdelegate product(ta, tb), to: Applicative

  # Monad

  @spec flat_map(Monad.t(a), (a -> Monad.t(b))) :: Monad.t(b) when a: var, b: var
  defdelegate flat_map(ta, f), to: Monad

  # MonadError

  @spec raise(MonadError.t(any), error) :: MonadError.t(none) when error: any
  defdelegate raise(example, error), to: MonadError

  @spec recover(MonadError.t(a), (error -> MonadError.t(a))) :: MonadError.t(a) when a: var, error: any
  defdelegate recover(ta, f), to: MonadError

  @spec lift_ok_or_error(MonadError.t(any), MonadError.ok_or_error(a)) :: MonadError.t(a) when a: var
  defdelegate lift_ok_or_error(example, result), to: MonadError

  @spec attempt(MonadError.t(a)) :: MonadError.t(MonadError.ok_or_error(a)) when a: var
  defdelegate attempt(ta), to: MonadError

  # Semigroup

  @spec combine(Semigroup.t(), Semigroup.t()) :: Semigroup.t()
  defdelegate combine(a, b), to: Semigroup

  # Monoid

  @spec zero(Monoid.t()) :: Monoid.t()
  defdelegate zero(example), to: Monoid

  # Foldable

  @spec fold_left(Foldable.t(a), b, (b, a -> b)) :: b when a: var, b: var
  defdelegate fold_left(ta, zero, f), to: Foldable

  # Reducible

  @spec reduce_left(Reducible.t(a), (a, a -> a)) :: a when a: var
  defdelegate reduce_left(ta, f), to: Reducible

  ## Delegates to protocols' arrows

  defmodule Arrow do
    # Functor

    @spec map((a -> b)) :: (Functor.t(a) -> Functor.t(b)) when a: var, b: var
    defdelegate map(f), to: Functor.Arrow

    @spec as(Functor.t(any)) :: (a -> Functor.t(a)) when a: var
    defdelegate as(t), to: Functor.Arrow

    # Applicative

    @spec pure(Applicative.t(any)) :: (a -> Applicative.t(a)) when a: var
    defdelegate pure(example), to: Applicative.Arrow

    @spec ap(Applicative.t((a -> b))) :: (Applicative.t(a) -> Applicative.t(b))when a: var, b: var
    defdelegate ap(tf), to: Applicative.Arrow

    # Monad

    @spec flat_map((a -> Monad.t(b))) :: (Monad.t(a) -> Monad.t(b)) when a: var, b: var
    defdelegate flat_map(f), to: Monad.Arrow

    # MonadError

    @spec raise(error) :: (MonadError.t(any) -> MonadError.t(none)) when error: any
    defdelegate raise(example), to: MonadError.Arrow

    @spec recover((error -> MonadError.t(a))) :: (MonadError.t(a) -> MonadError.t(a)) when a: var, error: any
    defdelegate recover(ta), to: MonadError.Arrow

    @spec on_error(MonadError.t(a), (error -> MonadError.t(no_return) | no_return)) :: MonadError.t(a) when a: var, error: any
    defdelegate on_error(ta, f), to: MonadError

    @spec lift_ok_or_error(MonadError.t(any)) :: (MonadError.ok_or_error(a) -> MonadError.t(a)) when a: var
    defdelegate lift_ok_or_error(example), to: MonadError.Arrow
  end


  # # Effect # #

  defmodule Effect do

    alias Cat.Effect.{Async, Bracket, Sync}

    ## Delegates to protocols ##

    # Bracket

#    @spec bracket(
#            acquire: Bracket.t(a),
#            use: (a -> Bracket.t(b)),
#            release: (Bracket.exit_case(a) -> Bracket.t(no_return))
#          ) :: Bracket.t(b) when a: var, b: var
#    def bracket(acquire: acquire, use: use, release: release), do:
#      Bracket.bracket(acquire, use, release)
#
#    @spec guarantee(Bracket.t(a), finalize: Bracket.t(no_return)) :: Bracket.t(a) when a: var
#    def guarantee(ta, finalize: finalizer), do:
#      Bracket.guarantee(ta, finalizer)
#
#    @spec uncancelable(Bracket.t(a)) :: Bracket.t(a) when a: var
#    defdelegate uncancelable(ta), to: Bracket

    # Sync

    @spec defer((-> Sync.t(a))) :: Sync.t(a) when a: var
    defdelegate defer(taf), to: Sync

    @spec delay(Sync.t(any), (-> a)) :: Sync.t(a) when a: var
    defdelegate delay(example, xf), to: Sync

    # Async

    @spec async(Async.t(any), (Async.callback(a) -> Async.t(no_return) | no_return)) :: Async.t(a) when a: var
    defdelegate async(example, fun), to: Async

    @spec async_effect(Async.t(a), (Bracket.exit_case(a) -> Async.t(no_return))) :: Async.t(no_return) when a: var
    defdelegate async_effect(effect, on_complete), to: Async
    
    @spec never(Async.t(any)) :: Async.t(none)
    defdelegate never(example), to: Async

    ## Delegates to protocols' arrows

    defmodule Arrow do
      # Bracket

#      @spec bracket(
#              acquire: Bracket.t(a),
#              release: (Bracket.exit_case(a) -> Bracket.t(no_return))
#            ) :: (Bracket.Arrow.use(a, b) -> Bracket.t(b)) when a: var, b: var
#      def bracket(acquire: acquire, release: release), do: Bracket.Arrow.bracket(acquire: acquire, release: release)
#
#      @spec guarantee(Bracket.t(no_return)) :: (Bracket.t(a) -> Bracket.t(a)) when a: var
#      defdelegate guarantee(finalizer), to: Bracket.Arrow

      # Sync

      @spec delay(Sync.t(any)) :: ((-> a) -> Sync.t(a)) when a: var
      defdelegate delay(example), to: Sync.Arrow

      # Async

      @spec async(Async.t(any)) :: ((Async.callback(a) -> Async.t(no_return) | no_return) -> Async.t(a)) when a: var
      defdelegate async(example), to: Async.Arrow

      @spec async_effect((Bracket.exit_case(a) -> Async.t(no_return))) :: (Async.t(a) -> Async.t(no_return)) when a: var
      defdelegate async_effect(on_complete), to: Async.Arrow
    end
  end

end
