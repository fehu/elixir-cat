defmodule Cat.Result do
  @moduledoc false

  defmodule Done do
    defstruct []
    @type t() :: %__MODULE__{}
  end
  
  defmodule Success do
    defstruct [:val]
    @type t(x) :: % __MODULE__{val: x}
  end

  defmodule Failure do
    defstruct [:reasons]
    @type t(e) :: %__MODULE__{reasons: reasons(e)}
    @type reasons(reason) :: nonempty_list(reason)
  end

  @type done() :: Done.t()
  @type success(x) :: Success.t(x)
  @type failure(e) :: Failure.t(e)

  @type t(x, e) :: success(x) | failure(e)
  @type t(x) :: success(x) | failure(any)
  @type t() :: done() | failure(any)

  @type liftable() :: :ok | {:error, any()}
  @type liftable(x) :: {:ok, x} | {:error, any()}


  @spec ok(x) :: success(x) when x: var
  def ok(x), do: %Success{val: x}

  @spec done() :: done()
  def done(), do: %Done{}

  @spec fail(e | Failure.reasons(e)) :: failure(e) when e: var
  def fail(reasons = [_ | _]), do: fail_many(reasons)
  def fail(reason), do: fail_one(reason)

  @spec fail_one(e) :: failure(e) when e: var
  def fail_one(reason), do: %Failure{reasons: [reason]}

  @spec fail_many(Failure.reasons(e)) :: failure(e) when e: var
  def fail_many(reasons), do: %Failure{reasons: reasons}

  @spec lift(liftable() | liftable(x)) :: t() | t(x) when x: var
  def lift(:ok), do: done()
  def lift({:ok, x}), do: ok(x)
  def lift({:error, error}), do: fail_one(error)

  @spec as(t(any)| t(), x) :: t(x) when x: var
  def as(%Success{}, x), do: %Success{val: x}
  def as(%Done{}, x), do: %Success{val: x}
  def as(fail=%Failure{}, _), do: fail

  @spec success?(t() | t(any())) :: boolean
  def success?(%Failure{}), do: false
  def success?(_), do: true

  @spec failure?(t() | t(any())) :: boolean
  def failure?(%Failure{}), do: true
  def failure?(_), do: false

  @spec get!(t(x)) :: x when x: var
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
  @spec map(Result.t(x), (x -> y)) :: Result.t(y) when x: var, y: var
  def map(%Success{val: x}, f), do: %Success{val: f.(x)}
  def map(done=%Done{}, _), do: done
  def map(fail=%Failure{}, _), do: fail

  @spec as(Result.t(any) | Result.t(), x) :: Result.t(x) when x: var
  defdelegate as(t, x), to: Result
end

defimpl Applicative, for: [Done, Failure, Success] do
  @spec pure(Result.t(any), x) :: Result.t(x) when x: var
  def pure(_, x), do: %Success{val: x}

  @spec ap(Result.t((x -> y)), Result.t(x)) :: Result.t(y) when x: var, y: var
  def ap(%Success{val: f}, %Success{val: x}), do: %Success{val: f.(x)}
  def ap(%Failure{reasons: rs1}, %Failure{reasons: rs2}), do: %Failure{reasons: rs1 ++ rs2}
  def ap(fail=%Failure{}, _), do: fail
  def ap(_, fail=%Failure{}), do: fail
  def ap(%Done{}, y), do: y
  def ap(x, %Done{}), do: x

  defdelegate product(tx, ty), to: Cat.Applicative.Default
end

defimpl Monad, for: [Done, Failure, Success] do
  @spec flat_map(Result.t(x), (x -> Result.t(y))) :: Result.t(y) when x: var, y: var
  def flat_map(%Success{val: x}, f), do: f.(x)
  def flat_map(fail=%Failure{}, _), do: fail
  def flat_map(done=%Done{}, _), do: done
end

defimpl MonadError, for: [Done, Failure, Success] do
  @spec raise(Result.t(any), error) :: Result.t(none) when error: any
  def raise(_, error), do: %Failure{reasons: [error]}

  @spec recover(Result.t(x), (errors -> Result.t(x))) :: Result.t(x) when x: var, errors: Failure.reasons(any)
  def recover(%Failure{reasons: errors}, f), do: f.(errors)
  def recover(%Done{}, f), do: f.([:empty])
  def recover(succ=%Success{}, _), do: succ

  @spec lift_ok_or_error(Result.t(any), MonadError.ok_or_error(x)) :: Result.t(x) when x: var
  def lift_ok_or_error(_, {:ok, x}), do: %Success{val: x}
  def lift_ok_or_error(_, {:error, e}), do: %Failure{reasons: [e]}

  @spec attempt(Result.t(x)) :: Result.t(MonadError.ok_or_error(x)) when x: var
  defdelegate attempt(tx), to: Cat.MonadError.Default
end
