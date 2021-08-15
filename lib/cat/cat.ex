defmodule Cat do
  @moduledoc false

  ## Delegates to protocols ##

  # Functor

  @spec map(Functor.t(x), (x -> y)) :: Functor.t(y) when x: var, y: var
  defdelegate map(tx, f), to: Functor

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
  end

end
