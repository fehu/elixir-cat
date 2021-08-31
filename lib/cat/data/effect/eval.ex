alias Cat.Fun
alias Cat.Effect.MonadCancel
alias Cat.Macros.Common, as: Macros
require Fun

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
             | {:cancelable, t(any)}
             | :canceled
             | {:on_cancel, t(any), t(no_return)}
             | {:async, (Async.callback(any) -> t(no_return) | no_return)}
             | :cede
             | {:start, t(any)}
             | {:race_pair, t(any), t(any)}

  @type t(_x) :: %__MODULE__{op: op}

  # TODO:
  # * Sleep
  # * Retry
  # * EvalOn
  # * Blocking

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

  # # Private Constructors # #

  @spec poll() :: MonadCancel.poll # :: t(a) -> t(a)
  defp poll(), do: fn eval -> %__MODULE__{op: {:cancelable, eval}} end

  # # Extra Constructors # #

  defmacro safe(x) do
    success = quote do: &Cat.Eval.pure/1
    failure = quote do: &Cat.Eval.error/1
    Macros.safe(success, failure, x)
  end

  @spec safe_((-> x)) :: t(x) when x: var
  def safe_(fx), do: safe(fx.())

  defmacro flat_safe(x) do
    failure = quote do: &Cat.Eval.error/1
    Macros.flat_safe(failure, x)
  end

  @spec flat_safe_((-> t(x))) :: t(x) when x: var
  def flat_safe_(fx), do: flat_safe(fx.())

  # # Execution # #

  @spec exec_sync(Eval.t(a)) :: MonadError.ok_or_error(a) when a: var
  def exec_sync(ta) do
    # TODO
  end

  @spec exec_async(Eval.t(a), (MonadError.ok_or_error(a) -> Eval.t(no_return) | no_return)) :: :ok when a: var
  def exec_async(ta, callback) do
    # TODO
  end

  @typep fiber_impl :: StackSafe
  @typep ctrl_it :: non_neg_integer

  # Runs the fiber at once
  @default_ctrl_it 10
  @spec exec_fiber(Eval.t(a), fiber_impl, ctrl_it) :: EvalFiber.t(a) when a: var
  def exec_fiber(eval, impl \\ StackSafe, ctrl_it \\ @default_ctrl_it)
  def exec_fiber(eval, StackSafe, ctrl_it), do:
    Cat.Effect.EvalFiber.StackSafe.run(eval, ctrl_it)

  # # Implementation # #

  defmodule StackSafe do
    @typep error :: any
    @typep chain :: Enumerable.t(link)
    @typep link :: {:pure, any}
                 | {:delay, (-> any)}
                 | {:map, (any -> any)}
                 | {:flat_map, (any -> chain)}
                 | {:error, error}
                 | {:recover, (error -> chain)}
                 | {:uncancelable, (-> chain)}
                 | {:cancelable, (-> chain)}
                 | :canceled
                 | {:on_cancel, (-> chain)}
                 # | {:async, (Async.callback(any) -> t(no_return) | no_return)}
                 | :cede
                 | :start
                 # | {:race_pair, t(any), t(any)}

    # TODO: cancel scope?

    @spec to_chain(Eval.t(any)) :: chain
    def to_chain(eval), do: to_chain(eval, [])

    @spec to_chain(Eval.t(any), chain) :: chain
    defp to_chain(eval, chain) do
      prepend = fn opts -> opts ++ chain end # fn opts -> Stream.concat opts, chain end
      compose = fn f -> Fun.compose(&to_chain(&1, []), f) end
      delayed = fn ea -> fn -> to_chain ea, [] end end
      uncancelable = fn f -> fn -> to_chain Eval.flat_safe(f.(Eval.poll())), [] end end
      case eval.op do
        {:pure, a}           -> prepend.(pure: a)
        # TODO
        {:delay, fa}         -> prepend.(delay: fa)
        {:map, ea, f}        -> to_chain ea, prepend.(map: f)
        {:flat_map, ea, f}   -> to_chain ea, prepend.(flat_map: compose.(f))
        {:error, error}      -> prepend.(error: error)
        {:recover, ea, f}    -> to_chain ea, prepend.(recover: compose.(f))
        {:uncancelable, f}   -> prepend.(uncancelable: uncancelable.(f))
        {:cancelable, ea}    -> prepend.(cancelable: delayed.(ea))
        :canceled            -> prepend.(:canceled)
        {:on_cancel, ea, eu} -> to_chain ea, prepend.(on_cancel: delayed.(eu))
        # TODO
        # {:async, (Async.callback(any) -> t(no_return) | no_return)}
        {:async, f}          -> prepend.(:async)
        :cede                -> prepend.(:cede)
        {:start, ea}         -> to_chain ea, prepend.(:start)
        # TODO
        # {:race_pair, ea, eb} -> raise "TODO" # TODO
      end
    end
  end
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

# # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # Fiber # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # #

defmodule Cat.Effect.EvalFiber do
  @enforce_keys [:task]
  defstruct [:task]
  @type t() :: %__MODULE__{task: Task.t}

  # # Implementation # #

  defmodule StackSafe do
    # Runs the fiber at once
    @spec run(Eval.t, ctrl_it) :: EvalFiber.t
    def run(eval, ctrl_it), do:
      %Cat.Effect.EvalFiber{
        task: Task.async fn -> run_chain Eval.StackSafe.to_chain(eval), ctrl_it end
      }


    @spec run_chain(Eval.StackSafe.chain, ctrl_it) :: MonadCancel.outcome(any)
    def run_chain(chain, ctrl_it), do:
      do_run_chain(chain, :first, ctrl_it, %{ctrl_it: ctrl_it})

    defmacrop safe_outcome(x) do
      success = quote do: &({:ok, &1})
      failure = quote do: &({:error, &1})
      Macros.safe(success, failure, x)
    end

    defmacrop flat_safe_outcome(x) do
      failure = quote do: &({:error, &1})
      Macros.flat_safe(failure, x)
    end

    @typep ctrl_it :: non_neg_integer
    @typep do_run_chain_cfg :: %{ required(:ctrl_every)  => ctrl_it,
                                  optional(:canceled)    => boolean,
                                  optional(:cancel_mask) => non_neg_integer
                                }
    @spec do_run_chain(Eval.StackSafe.chain, MonadCancel.outcome(any) | :first, ctrl_it | nil, do_run_chain_cfg) :: MonadCancel.outcome(any)
    defp do_run_chain([], result, ctrl_it, cfg), do: result
    defp do_run_chain(chain, result, 0, cfg) do
      receive do
        :cancel -> do_run_chain [:canceled | chain], result, nil, Map.put(cfg, :canceled, true)
      after 0 ->
        do_run_chain chain, result, cfg.ctrl_every, cfg
      end
    end
    defp do_run_chain([head | tail], :canceled, ctrl_it, cfg) do
      case head do
        {:on_cancel, cancel_chain} ->
          do_run_chain(cancel_chain, :first, cfg.ctrl_every, cfg)
          do_run_chain(tail, :canceled, nil, cfg)
        _ ->
          do_run_chain(tail, :canceled, nil, cfg)
      end
    end
    defp do_run_chain([:canceled | tail], result, ctrl_it, cfg) do
      cfg_set_masked_cancel = fn -> Map.put(cfg, :canceled, true) end
      case Map.get(cfg, :cancel_mask, 0) do
        0 -> do_run_chain tail, :canceled, ctrl_it - 1, cfg
        _ -> do_run_chain tail, :canceled, ctrl_it - 1, cfg_set_masked_cancel.()
      end
    end
    @independent_ops [:pure, :delay, :error, :recover, :uncancelable, :cancelable, :on_cancel, :cede, :start]
    defp do_run_chain([{op, v} | tail], result, ctrl_it, cfg)
         when (result == :first or (is_tuple(result) and elem(result, 1) == :ok))
          and (op in @independent_ops)
           do
      cfg_cancel_mask_more = fn -> Map.update(cfg, :cancel_mask, 1, &Kernel.+(&1, 1)) end
      cfg_cancel_mask_less = fn -> Map.update!(cfg, :cancel_mask, &Kernel.-(&1, 1)) end
      case op do
        :pure         -> do_run_chain tail, {:ok, v}, ctrl_it - 1, cfg
        :delay        -> do_run_chain tail, safe_outcome(v.()), ctrl_it - 1, cfg
        :error        -> do_run_chain tail, {:error, v}, ctrl_it - 1, cfg
        :recover      -> do_run_chain tail, result, ctrl_it - 1, cfg
        :uncancelable -> do_run_chain(v.() ++ tail, result, ctrl_it - 1, cfg_cancel_mask_more.()) # TODO
        :cancelable   -> do_run_cancelable(tail, v, result, ctrl_it, cfg_cancel_mask_less.())
        :on_cancel    -> do_run_chain tail, result, ctrl_it - 1, cfg
        :cede         -> :todo # TODO
        :start        -> :todo # TODO
      end
    end
    defp do_run_chain([op | tail], {:ok, val}, ctrl_it, cfg) do
      case op do
        {:map, f}      -> do_run_chain tail, safe_outcome(f.(val)), ctrl_it - 1, cfg
        {:flat_map, f} -> do_run_chain(f.(val) ++ tail, :first, ctrl_it - 1, cfg) # TODO
      end
    end
    defp do_run_chain(chain, {:error, error}, ctrl_it, cfg) do
      case chain do
        [{:recover, f} | tail] -> do_run_chain tail, flat_safe_outcome(f.(error)), ctrl_it - 1, cfg
        [_             | tail] -> do_run_chain tail, {:error, error}, ctrl_it - 1, cfg
      end
    end

    @spec do_run_cancelable(
            chain :: Eval.StackSafe.chain,
            chain_f :: (-> Eval.StackSafe.chain),
            result :: MonadCancel.outcome(any) | :first,
            ctrl_it :: ctrl_it,
            cfg :: do_run_chain_cfg
          ) :: MonadCancel.outcome(any)
    defp do_run_cancelable(chain, chain_f, result, ctrl_it, cfg) do
      if Map.has_key?(cfg, :canceled) and Map.get(cfg, :cancel_mask, 0) == 0,
         do: do_run_chain(chain, :canceled, ctrl_it - 1, cfg),
         else: do_run_chain(chain_f.() ++ chain, result, ctrl_it - 1, cfg) # TODO
    end
  end
end

alias Cat.Effect.{Fiber, EvalFiber}

defimpl Fiber, for: EvalFiber do
  @spec cancel(EvalFiber.t(any)) :: Eval.t(no_return)
  def cancel(fiber=%EvalFiber{task: task}) do
    send(task.pid, :cancel)
    join(fiber)
    :no_return
  end

  @spec join(EvalFiber.t(a)) :: Eval.t(MonadCancel.outcome(a)) when a: var
  def join(fiber=%EvalFiber{task: task}) do
    if Process.alive?(task.pid) do
      Task.await(task, :infinity)
    else
      try do
        Task.await(task, 0)
      catch
        :exit, {:timeout, _} -> {:error, {:dead_fiber, fiber}}
      end
    end
  end

end
