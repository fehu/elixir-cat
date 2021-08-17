# TODO

defmodule Cat.Effect.Eval do
  @moduledoc false

  defmodule NoOp do
    defstruct []
  end

  defmodule Pure do
    @enforce_keys [:val]
    defstruct [:val]
  end

  defmodule Map do
    @enforce_keys [:eval, :fun]
    defstruct [:eval, :fun]
  end

  defmodule FlatMap do
    @enforce_keys [:eval, :fun]
    defstruct [:eval, :fun]
  end

  defmodule Error do
    @enforce_keys [:error]
    defstruct [:error]
  end

  defmodule Recover do
    @enforce_keys [:eval, :handle]
    defstruct [:eval, :handle]
  end

  defmodule Bracket do
    @enforce_keys [:acquire, :use, :release]
    defstruct [:acquire, :use, :release]
  end

  defmodule Delay do
    @enforce_keys [:effect]
    defstruct [:effect]
  end

  defmodule Suspend do
    @enforce_keys [:effect]
    defstruct [:effect]
  end

  defmodule Async do
    @enforce_keys [:exec]
    defstruct [:exec]
  end

  # [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend]

  @typep no_op :: %NoOp{}
  @typep pure(a) :: %Pure{val: a}
  @typep map(a, b) :: %Map{eval: t(a), fun: (a -> b)}
  @typep flat_map(a, b) :: %FlatMap{eval: t(a), fun: (a -> t(b))}
  @typep error :: %Error{error: any}
  @typep recover(a, b) :: %Recover{eval: t(a), handle: (any -> t(b))}
  @typep bracket(a, b) :: %Bracket{acquire: t(a), use: (a -> t(b)), release: (Bracket.exit_case(a) -> t(no_return))}
  @typep delay(a) :: %Delay{effect: (-> a)}
  @typep suspend(a) :: %Suspend{effect: t(a)}
  @typep async(a) :: %Async{exec: (Effect.Async.callback(a) -> t(no_return))}

  @type t(a) :: no_op
              | pure(a)
              | map(any, a)
              | flat_map(any, a)
              | error
              | recover(any, a)
              | bracket(any, a)
              | delay(a)
              | suspend(a)
              | async(a)

  @spec no_op :: t(none)
  def no_op, do: %NoOp{}

  @spec pure(a) :: t(a) when a: var
  def pure(a), do: %Pure{val: a}

  @spec map(t(a), (a -> b)) :: t(b) when a: var, b: var
  def map(ta, f), do: %Map{eval: ta, fun: f}

  @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: var, b: var
  def flat_map(ta, f), do: %FlatMap{eval: ta, fun: f}

  @spec error(any) :: t(none)
  def error(err), do: %Error{error: err}

  @spec recover(t(a), (error -> t(a))) :: t(a) when a: var, error: any
  def recover(ta, handle), do: %Recover{eval: ta, handle: handle}

  @spec bracket(t(a), (a -> t(b)), (Bracket.exit_case(a) -> t(no_return))) :: t(b) when a: var, b: var
  def bracket(acquire, use, release), do: %Bracket{acquire: acquire, use: use, release: release}

  @spec delay_((-> a)) :: t(a) when a: var
  def delay_(fx), do: %Delay{effect: fx}

  defmacro delay(a) do
    quote do: %Delay{effect: fn -> unquote(a) end}
  end

  @spec suspend_((-> t(a))) :: t(a) when a: var
  def suspend_(fta), do: %Suspend{effect: fta}

  defmacro suspend(ta) do
    quote do: %Suspend{effect: fn -> unquote(ta) end}
  end

  @spec async((Async.callback(a) -> t(no_return))) :: t(a) when a: var
  def async(fun), do: %Async{exec: fun}
end

#  alias Cat.{Applicative, Effect, Functor, Monad, MonadError}
#  alias Cat.Effect.Eval
#  alias Cat.Effect.Eval.{NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async}
#
#  defimpl Functor, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec map(Eval.t(a), (a -> b)) :: Eval.t(b) when a: var, b: var
#    defdelegate map(ta, f), to: Eval
#
#    @spec as(Eval.t(any), a) :: Eval.t(a) when a: var
#    defdelegate as(t, a), to: Functor.Default
#  end
#
#  defimpl Applicative, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec pure(Eval.t(any), a) :: Eval.t(a) when a: var
#    def pure(_, a), do: Eval.pure(a)
#
#    @spec ap(Eval.t((a -> b)), Eval.t(a)) :: Eval.t(b) when a: var, b: var
#    defdelegate ap(tf, ta), to: Applicative.Default.FromMonad
#
#    @spec product(Eval.t(a), Eval.t(b)) :: Eval.t({a, b}) when a: var, b: var
#    defdelegate product(ta, tb), to: Applicative.Default
#  end
#
#  defimpl Monad, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec flat_map(Eval.t(a), (a -> Eval.t(b))) :: Eval.t(b) when a: var, b: var
#    defdelegate flat_map(ta, f), to: Eval
#
#    @spec flat_tap(Eval.t(a), (a -> Eval.t(no_return))) :: Eval.t(a) when a: var
#    defdelegate flat_tap(ta, f), to: Cat.Monad.Default
#  end
#
#  defimpl MonadError, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec raise(Eval.t(any), error) :: Eval.t(none) when error: any
#    def raise(_, error), do: Eval.error(error)
#
#    @spec recover(Eval.t(a), (error -> Eval.t(a))) :: Eval.t(a) when a: var, error: any
#    defdelegate recover(ta, f), to: Eval
#
#    @spec lift_ok_or_error(Eval.t(any), MonadError.ok_or_error(a)) :: Eval.t(a) when a: var
#    def lift_ok_or_error(_, {:ok, a}), do: %Pure{val: a}
#    def lift_ok_or_error(_, {:error, e}), do: %Error{error: e}
#
#    @spec attempt(Eval.t(a)) :: Eval.t(MonadError.ok_or_error(a)) when a: var
#    defdelegate attempt(ta), to: Cat.MonadError.Default
#  end
#
#  defimpl Effect.Bracket, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec uncancelable((Effect.Bracket.poll -> Eval.t(a))) :: Eval.t(a) when a: var
#    def uncancelable(taf) do
#
#    end
#
#    @spec canceled(Eval.t(any)) :: Eval.t(none)
#    def canceled(example) do
#
#    end
#
#    @spec on_cancel(Eval.t(a), Eval.t(no_return)) :: Eval.t(a) when a: var
#    def on_cancel(ta, finalizer) do
#
#    end
#
#    @spec bracket(
#            (Effect.Bracket.poll -> Eval.t(a)),
#            (a -> Eval.t(b)),
#            (a, Effect.Bracket.exit_case(b) -> Eval.t(:no_return) | :no_return)
#          ) :: t(b) when a: var, b: var
#    def bracket(acquire, use, release) do
#
#    end
#
#    @spec guarantee(Eval.t(a), (Effect.Bracket.exit_case(a) -> Eval.t(no_return))) :: Eval.t(a) when a: var
#    def guarantee(ta, finalizer) do
#
#    end
#
#  #  @spec bracket(Eval.t(a), (a -> Eval.t(b)), (Effect.Bracket.exit_case(a) -> Eval.t(no_return))) :: Eval.t(b) when a: var, b: var
#  #  defdelegate bracket(acquire, use, release), to: Eval
#  #
#  #  @spec guarantee(Eval.t(a), Eval.t(no_return)) :: Eval.t(a) when a: var
#  #  defdelegate guarantee(ta, finalizer), to: Cat.Effect.Bracket.Default
#  #
#  #  @spec uncancelable(Eval.t(a)) :: Eval.t(a) when a: var
#  #  defdelegate uncancelable(ta), to: Cat.Effect.Bracket.Default
#  end
#
#  defimpl Effect.Sync, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec defer((-> Eval.t(a))) :: Eval.t(a) when a: var
#    defdelegate defer(taf), to: Eval, as: :suspend_
#
#    @spec delay(Eval.t(any), (-> a)) :: Eval.t(a) when a: var
#    def delay(_, xf), do: Eval.delay_(xf)
#  end
#
#  defimpl Effect.Async, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
#    @spec async(Eval.t(any), (Async.callback(a) -> no_return)) :: Eval.t(a) when a: var
#    defdelegate async(example, fun), to: Eval
#
#    @spec async_effect(Eval.t(a), (Bracket.exit_case(a) -> Eval.t(no_return))) :: Eval.t(no_return) when a: var
#    defdelegate async_effect(effect, on_complete), to: Cat.Effect.Async.Default
#
#    @spec never(Eval.t(any)) :: Eval.t(none)
#    defdelegate never(example), to: Cat.Effect.Async.Default
#  end
