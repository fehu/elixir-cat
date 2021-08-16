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
  @typep pure(x) :: %Pure{val: x}
  @typep map(x, y) :: %Map{eval: t(x), fun: (x -> y)}
  @typep flat_map(x, y) :: %FlatMap{eval: t(x), fun: (x -> t(y))}
  @typep error :: %Error{error: any}
  @typep recover(x, y) :: %Recover{eval: t(x), handle: (any -> t(y))}
  @typep bracket(x, y) :: %Bracket{acquire: t(x), use: (x -> t(y)), release: (Bracket.exit_case(x) -> t(no_return))}
  @typep delay(x) :: %Delay{effect: (-> x)}
  @typep suspend(x) :: %Suspend{effect: t(x)}
  @typep async(x) :: %Async{exec: (Effect.Async.callback(x) -> t(no_return))}

  @type t(x) :: no_op
              | pure(x)
              | map(any, x)
              | flat_map(any, x)
              | error
              | recover(any, x)
              | bracket(any, x)
              | delay(x)
              | suspend(x)
              | async(x)

  @spec no_op :: t(none)
  def no_op, do: %NoOp{}

  @spec pure(x) :: t(x) when x: var
  def pure(x), do: %Pure{val: x}

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(tx, f), do: %Map{eval: tx, fun: f}

  @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
  def flat_map(tx, f), do: %FlatMap{eval: tx, fun: f}

  @spec error(any) :: t(none)
  def error(err), do: %Error{error: err}

  @spec recover(t(x), (error -> t(x))) :: t(x) when x: var, error: any
  def recover(tx, handle), do: %Recover{eval: tx, handle: handle}

  @spec bracket(t(x), (x -> t(y)), (Bracket.exit_case(x) -> t(no_return))) :: t(y) when x: var, y: var
  def bracket(acquire, use, release), do: %Bracket{acquire: acquire, use: use, release: release}

  @spec delay_((-> x)) :: t(x) when x: var
  def delay_(fx), do: %Delay{effect: fx}

  defmacro delay(x) do
    quote do: %Delay{effect: fn -> unquote(x) end}
  end

  @spec suspend_((-> t(x))) :: t(x) when x: var
  def suspend_(ftx), do: %Suspend{effect: ftx}

  defmacro suspend(tx) do
    quote do: %Suspend{effect: fn -> unquote(tx) end}
  end

  @spec async((Async.callback(x) -> t(no_return))) :: t(x) when x: var
  def async(fun), do: %Async{exec: fun}
end

alias Cat.{Applicative, Effect, Functor, Monad, MonadError}
alias Cat.Effect.Eval
alias Cat.Effect.Eval.{NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async}

defimpl Functor, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec map(Eval.t(x), (x -> y)) :: Eval.t(y) when x: var, y: var
  defdelegate map(tx, f), to: Eval

  @spec as(Eval.t(any), x) :: Eval.t(x) when x: var
  defdelegate as(t, x), to: Functor.Default
end

defimpl Applicative, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec pure(Eval.t(any), x) :: Eval.t(x) when x: var
  def pure(_, x), do: Eval.pure(x)

  @spec ap(Eval.t((x -> y)), Eval.t(x)) :: Eval.t(y) when x: var, y: var
  defdelegate ap(tf, tx), to: Applicative.Default.FromMonad

  @spec product(Eval.t(x), Eval.t(y)) :: Eval.t({x, y}) when x: var, y: var
  defdelegate product(tx, ty), to: Applicative.Default
end

defimpl Monad, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec flat_map(Eval.t(x), (x -> Eval.t(y))) :: Eval.t(y) when x: var, y: var
  defdelegate flat_map(tx, f), to: Eval
end

defimpl MonadError, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec raise(Eval.t(any), error) :: Eval.t(none) when error: any
  def raise(_, error), do: Eval.error(error)

  @spec recover(Eval.t(x), (error -> Eval.t(x))) :: Eval.t(x) when x: var, error: any
  defdelegate recover(tx, f), to: Eval

  @spec lift_ok_or_error(Eval.t(any), MonadError.ok_or_error(x)) :: Eval.t(x) when x: var
  def lift_ok_or_error(_, {:ok, x}), do: %Pure{val: x}
  def lift_ok_or_error(_, {:error, e}), do: %Error{error: e}

  @spec attempt(Eval.t(x)) :: Eval.t(MonadError.ok_or_error(x)) when x: var
  defdelegate attempt(tx), to: Cat.MonadError.Default
end

defimpl Effect.Bracket, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec bracket(Eval.t(x), (x -> Eval.t(y)), (Effect.Bracket.exit_case(x) -> Eval.t(no_return))) :: Eval.t(y) when x: var, y: var
  defdelegate bracket(acquire, use, release), to: Eval

  @spec guarantee(Eval.t(x), Eval.t(no_return)) :: Eval.t(x) when x: var
  defdelegate guarantee(tx, finalizer), to: Cat.Effect.Bracket.Default

  @spec uncancelable(Eval.t(x)) :: Eval.t(x) when x: var
  defdelegate uncancelable(tx), to: Cat.Effect.Bracket.Default
end

defimpl Effect.Sync, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec defer((-> Eval.t(x))) :: Eval.t(x) when x: var
  defdelegate defer(txf), to: Eval, as: :suspend_

  @spec delay(Eval.t(any), (-> x)) :: Eval.t(x) when x: var
  def delay(_, xf), do: Eval.delay_(xf)
end

defimpl Effect.Async, for: [NoOp, Pure, Map, FlatMap, Error, Bracket, Delay, Suspend, Async] do
  @spec async(Eval.t(any), (Async.callback(x) -> no_return)) :: Eval.t(x) when x: var
  defdelegate async(example, fun), to: Eval

  @spec async_effect(Eval.t(x), (Bracket.exit_case(x) -> Eval.t(no_return))) :: Eval.t(no_return) when x: var
  defdelegate async_effect(effect, on_complete), to: Cat.Effect.Async.Default

  @spec never(Eval.t(any)) :: Eval.t(none)
  defdelegate never(example), to: Cat.Effect.Async.Default
end
