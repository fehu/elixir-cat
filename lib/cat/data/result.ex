defmodule Cat.Result do
  @moduledoc false

  defmodule Done do
    defstruct []
    @type t() :: %__MODULE__{}
  end
  
  defmodule Success do
    defstruct [:val]
    @type t(a) :: % __MODULE__{val: a}
  end

  defmodule Failure do
    defstruct [:reasons]
    @type t(e) :: %__MODULE__{reasons: reasons(e)}
    @type reasons(reason) :: nonempty_list(reason)
  end

  @type done() :: Done.t()
  @type success(a) :: Success.t(a)
  @type failure(e) :: Failure.t(e)

  @type t(a, e) :: success(a) | failure(e)
  @type t(a) :: success(a) | failure(any)
  @type t() :: done() | failure(any)

  @type liftable() :: :ok | {:error, any()}
  @type liftable(a) :: {:ok, a} | {:error, any()}


  @spec ok(a) :: success(a) when a: var
  def ok(a), do: %Success{val: a}

  @spec done() :: done()
  def done(), do: %Done{}

  @spec fail(e | Failure.reasons(e)) :: failure(e) when e: var
  def fail(reasons = [_ | _]), do: fail_many(reasons)
  def fail(reason), do: fail_one(reason)

  @spec fail_one(e) :: failure(e) when e: var
  def fail_one(reason), do: %Failure{reasons: [reason]}

  @spec fail_many(Failure.reasons(e)) :: failure(e) when e: var
  def fail_many(reasons), do: %Failure{reasons: reasons}

  @spec lift(liftable() | liftable(a)) :: t() | t(a) when a: var
  def lift(:ok), do: done()
  def lift({:ok, a}), do: ok(a)
  def lift({:error, error}), do: fail_one(error)

  @spec as(t(any)| t(), a) :: t(a) when a: var
  def as(%Success{}, a), do: %Success{val: a}
  def as(%Done{}, a), do: %Success{val: a}
  def as(fail=%Failure{}, _), do: fail

  @spec success?(t() | t(any())) :: boolean
  def success?(%Failure{}), do: false
  def success?(_), do: true

  @spec failure?(t() | t(any())) :: boolean
  def failure?(%Failure{}), do: true
  def failure?(_), do: false

  @spec get!(t(a)) :: a when a: var
  def get!(%Success{val: value}), do: value

  @spec failure_reasons(t() | t(any)) :: [any]
  def failure_reasons(%Failure{reasons: reasons}), do: reasons
  def failure_reasons(_), do: []

  @spec failure_reasons!(t() | t(any)) :: Failure.reasons(any)
  def failure_reasons!(%Failure{reasons: reasons}), do: reasons
end

alias Cat.{Applicative, Functor, Monad, MonadError, Result}
alias Cat.Result.{Done, Failure, Success}

defimpl Functor, for: [Done, Failure, Success] do
  @spec map(Result.t(a), (a -> b)) :: Result.t(b) when a: var, b: var
  def map(%Success{val: a}, f), do: %Success{val: f.(a)}
  def map(done=%Done{}, _), do: done
  def map(fail=%Failure{}, _), do: fail

  @spec as(Result.t(any) | Result.t(), a) :: Result.t(a) when a: var
  defdelegate as(t, a), to: Result
end

defimpl Applicative, for: [Done, Failure, Success] do
  @spec pure(Result.t(any), a) :: Result.t(a) when a: var
  def pure(_, a), do: %Success{val: a}

  @spec ap(Result.t((a -> b)), Result.t(a)) :: Result.t(b) when a: var, b: var
  def ap(%Success{val: f}, %Success{val: a}), do: %Success{val: f.(a)}
  def ap(%Failure{reasons: rs1}, %Failure{reasons: rs2}), do: %Failure{reasons: rs1 ++ rs2}
  def ap(fail=%Failure{}, _), do: fail
  def ap(_, fail=%Failure{}), do: fail
  def ap(%Done{}, b), do: b
  def ap(a, %Done{}), do: a

  defdelegate product(ta, tb), to: Cat.Applicative.Default
  defdelegate product_l(ta, tb), to: Applicative.Default
  defdelegate product_r(ta, tb), to: Applicative.Default
  defdelegate map2(ta, tb, f), to: Applicative.Default
end

defimpl Monad, for: [Done, Failure, Success] do
  @spec flat_map(Result.t(a), (a -> Result.t(b))) :: Result.t(b) when a: var, b: var
  def flat_map(%Success{val: a}, f), do: f.(a)
  def flat_map(fail=%Failure{}, _), do: fail
  def flat_map(done=%Done{}, _), do: done

  @spec flat_tap(Result.t(a), (a -> Result.t(no_return))) :: Result.t(a) when a: var
  defdelegate flat_tap(ta, f), to: Cat.Monad.Default
end

defimpl MonadError, for: [Done, Failure, Success] do
  @spec raise(Result.t(any), error) :: Result.t(none) when error: any
  def raise(_, error), do: %Failure{reasons: [error]}

  @spec recover(Result.t(a), (errors -> Result.t(a))) :: Result.t(a) when a: var, errors: Failure.reasons(any)
  def recover(%Failure{reasons: errors}, f), do: f.(errors)
  def recover(%Done{}, f), do: f.([:empty])
  def recover(succ=%Success{}, _), do: succ

  @spec on_error(Result.t(a), (error -> Result.t(no_return))) :: Result.t(a) when a: var, error: any
  defdelegate on_error(ta, f), to: Cat.MonadError.Default

  @spec lift_ok_or_error(Result.t(any), MonadError.ok_or_error(a)) :: Result.t(a) when a: var
  def lift_ok_or_error(_, {:ok, a}), do: %Success{val: a}
  def lift_ok_or_error(_, {:error, e}), do: %Failure{reasons: [e]}

  @spec attempt(Result.t(a)) :: Result.t(MonadError.ok_or_error(a)) when a: var
  defdelegate attempt(ta), to: Cat.MonadError.Default
end
