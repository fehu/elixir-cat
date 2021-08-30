alias Cat.Effect.MonadCancel

defmodule Cat.Effect.Eval do
  @moduledoc false

  @enforce_keys [:op]
  defstruct [:op]

  @typep error :: any
  @typep op :: {:pure, any}
             | {:delay, (-> any)}
             | {:map, t(any), (any -> any)}
             | {:flat_map, t(any), (any -> t(any))}
             | {:error, error}
             | {:recover, t(any), (error -> t(any))}
             | {:uncancelable, (MonadCancel.poll -> t(any))}
             | :canceled
             | {:on_cancel, t(any), t(no_return)}
             | {:async, (Async.callback(any) -> t(no_return) | no_return)}
             | {:cede}
             | {:start, t(any)}
             | {:race_pair, t(any), t(any)}

  @type t(_x) :: %__MODULE__{op: op}

  # # Constructors # #

  @spec pure(a) :: t(a) when a: var
  def pure(a), do: %__MODULE__{op: {:pure, a}}

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(ta, f), do: %__MODULE__{op: {:map, ta, f}}

  @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: var, b: var
  def flat_map(ta, f), do: %__MODULE__{op: {:flat_map, ta, f}}

  @spec error(any) :: t(none)
  def error(err), do: %__MODULE__{op: {:error, err}}

  @spec recover(t(a), (error -> t(a))) :: t(a) when a: var, error: any
  def recover(ta, handle), do: %__MODULE__{op: {:recover, ta, handle}}

  @spec uncancelable((MonadCancel.poll -> t(a))) :: t(a) when a: var
  def uncancelable(txf), do: %__MODULE__{op: {:uncancelable, txf}}

  @spec canceled() :: t(none)
  def canceled(), do: %__MODULE__{op: :canceled}

  @spec on_cancel(t(a), t(no_return)) :: t(a) when a: var
  def on_cancel(ta, finalizer), do: %__MODULE__{op: {:on_cancel, ta, finalizer}}

  @spec delay((-> a)) :: t(a) when a: var
  def delay(af), do: %__MODULE__{op: {:delay, af}}

  @spec async((Async.callback(a) -> Eval.t(no_return) | no_return)) :: Eval.t(a) when a: var
  def async(fun), do: %__MODULE__{op: {:async, fun}}

  @spec cede() :: Eval.t(no_return)
  def cede(), do: %__MODULE__{op: :cede}

  @spec start(Eval.t(a)) :: Eval.t(Fiber.Eval.t(Eval.t, a)) when a: var
  def start(ta), do: %__MODULE__{op: {:start, ta}}

  @spec race_pair(Eval.t(a), Eval.t(b)) :: Eval.t(Spawn.race_pair_out(a, b)) when a: var, b: var
  def race_pair(ta, tb), do: %__MODULE__{op: {:race_pair, ta, tb}}

end

alias Cat.{Applicative, Functor, Monad, MonadError}
alias Cat.Effect.{Async, Eval, Spawn, Sync}

defimpl Functor, for: Eval do
  @spec map(Eval.t(a), (a -> b)) :: Eval.t(b) when a: var, b: var
  defdelegate map(ta, f), to: Eval

  @spec as(Eval.t(any), a) :: Eval.t(a) when a: var
  defdelegate as(t, a), to: Functor.Default
end

defimpl Applicative, for: Eval do
  @spec pure(Eval.t(any), a) :: Eval.t(a) when a: var
  def pure(_, a), do: Eval.pure(a)

  @spec ap(Eval.t((a -> b)), Eval.t(a)) :: Eval.t(b) when a: var, b: var
  defdelegate ap(tf, ta), to: Applicative.Default.FromMonad

  @spec product(Eval.t(a), Eval.t(b)) :: Eval.t({a, b}) when a: var, b: var
  defdelegate product(ta, tb), to: Applicative.Default

  @spec product_l(Eval.t(a), Eval.t(any)) :: Eval.t(a) when a: var
  defdelegate product_l(ta, tb), to: Applicative.Default

  @spec product_r(Eval.t(any), Eval.t(b)) :: Eval.t(b) when b: var
  defdelegate product_r(ta, tb), to: Applicative.Default

  @spec map2(Eval.t(a), Eval.t(b), (a, b -> c)) :: Eval.t(c) when a: var, b: var, c: var
  defdelegate map2(ta, tb, f), to: Applicative.Default

end

defimpl Monad, for: Eval do
  @spec flat_map(Eval.t(a), (a -> Eval.t(b))) :: Eval.t(b) when a: var, b: var
  defdelegate flat_map(ta, f), to: Eval

  @spec flat_tap(Eval.t(a), (a -> Eval.t(no_return))) :: Eval.t(a) when a: var
  defdelegate flat_tap(ta, f), to: Monad.Default

  @spec flatten(Eval.t(Eval.t(a))) :: Eval.t(a) when a: var
  defdelegate flatten(tta), to: Monad.Default
end

defimpl MonadError, for: Eval do
  @spec raise(Eval.t(any), error) :: Eval.t(none) when error: any
  def raise(_, error), do: Eval.error(error)

  @spec recover(Eval.t(a), (error -> Eval.t(a))) :: Eval.t(a) when a: var, error: any
  defdelegate recover(ta, f), to: Eval

  @spec on_error(Eval.t(a), (error -> Eval.t(no_return) | no_return)) :: Eval.t(a) when a: var, error: any
  defdelegate on_error(ta, f), to: MonadError.Default

  @spec lift_ok_or_error(Eval.t(any), Eval.ok_or_error(a)) :: Eval.t(a) when a: var
  defdelegate lift_ok_or_error(example, result), to: MonadError.Default

  @spec attempt(Eval.t(a)) :: Eval.t(Eval.ok_or_error(a)) when a: var
  defdelegate attempt(ta), to: MonadError.Default
end

defimpl MonadCancel, for: Eval do
  @spec uncancelable((MonadCancel.poll -> Eval.t(a))) :: Eval.t(a) when a: var
  defdelegate uncancelable(txf), to: Eval

  @spec canceled(Eval.t(any)) :: Eval.t(none)
  defdelegate canceled(example), to: Eval

  @spec on_cancel(Eval.t(a), Eval.t(no_return)) :: Eval.t(a) when a: var
  defdelegate on_cancel(ta, finalizer), to: Eval

  @spec bracket((MonadCancel.poll -> Eval.t(a)), (a -> Eval.t(b)), (a, MonadCancel.outcome(b) -> Eval.t(no_return) | no_return)) :: Eval.t(b) when a: var, b: var
  defdelegate bracket(acquire, use, release), to: MonadCancel.Default

  @spec guarantee(Eval.t(a), (MonadCancel.outcome(a) -> Eval.t(no_return) | no_return)) :: Eval.t(a) when a: var
  defdelegate guarantee(ta, finalizer), to: MonadCancel.Default
end

defimpl Sync, for: Eval do
  @spec defer(Eval.t(any), (-> Eval.t(a))) :: Eval.t(a) when a: var
  defdelegate defer(example, taf), to: Sync.Default

  @spec delay(Eval.t(any), (-> a)) :: Eval.t(a) when a: var
  defdelegate delay(example, xf), to: Eval
end

defimpl Async, for: Eval do
  @spec async(Eval.t(any), (Async.callback(a) -> Eval.t(no_return) | no_return)) :: Eval.t(a) when a: var
  def async(_, fun), do: Eval.async(fun)

  @spec async_effect(Eval.t(a), (MonadCancel.outcome(a) -> Eval.t(no_return) | no_return)) :: Eval.t(no_return) when a: var
  defdelegate async_effect(effect, on_complete), to: Async.Default

  @spec never(Eval.t(any)) :: Eval.t(none)
  defdelegate never(example), to: Async.Default
end

defimpl Spawn, for: Eval do
  @spec start(Eval.t(a)) :: Eval.t(Fiber.Eval.t(Eval.t, a)) when a: var
  defdelegate start(ta), to: Eval

  @spec never(Eval.t(any)) :: Eval.t(none)
  defdelegate never(example), to: Async.Default

  @spec cede(Eval.t(any)) :: Eval.t(no_return)
  def cede(_), do: Eval.cede

  @spec background(Eval.t(a)) :: Resource.Eval.t(Eval.t, Eval.t(MonadCancel.outcome(a))) when a: var
  defdelegate background(ta), to: Spawn.Default

  @spec race_pair(Eval.t(a), Eval.t(b)) :: Eval.t(Spawn.race_pair_out(a, b)) when a: var, b: var
  defdelegate race_pair(ta, tb), to: Eval

  @spec race(Eval.t(a), Eval.t(b)) :: Eval.t(Either.Eval.t(a, b)) when a: var, b: var
  defdelegate race(ta, tb), to: Spawn.Default

  @spec both(Eval.t(a), Eval.t(b)) :: Eval.t({a, b}) when a: var, b: var
  defdelegate both(ta, tb), to: Spawn.Default
end
