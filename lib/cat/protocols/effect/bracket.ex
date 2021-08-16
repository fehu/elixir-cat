defprotocol Cat.Effect.Bracket do
  @moduledoc """
  Resource management & basic cancellation.

  Bracket defines
    * `bracket(acquire: t(x), use: (x -> t(y)), release: (exit_case(x) -> t(no_return))) :: t(y)`
    * `guarantee(t(x), (exit_case(x) -> t(no_return))) :: t(x)`
    * `uncancelable(t(x)) :: t(x)`

  **It must also be `MonadError, `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `Bracket.Default`):
    * `guarantee(t(x), always: t(no_return)) :: t(x)`
  """

  @type t(_x) :: term

  @type exit_case(x) :: {:ok, x} | {:error, any} | :canceled

  @spec bracket(t(x), (x -> t(y)), (exit_case(x) -> t(no_return))) :: t(y) when x: var, y: var
  def bracket(acquire, use, release)

  @spec guarantee(t(x), (exit_case(x) -> t(no_return))) :: t(x) when x: var
  def guarantee(tx, finalizer)

  @spec uncancelable(t(x)) :: t(x) when x: var
  def uncancelable(tx)
end

alias Cat.Applicative
alias Cat.Effect.Bracket
alias Cat.Fun

require Fun

defmodule Cat.Effect.Bracket.Arrow do
  @type use(x, y) :: (x -> Bracket.t(y))

  @spec bracket(
          acquire: Bracket.t(x),
          release: (Bracket.exit_case(x) -> Bracket.t(no_return))
        ) :: (use(x, y) -> Bracket.t(y)) when x: var, y: var
  def bracket(acquire: acquire, release: release), do: &Bracket.bracket(acquire, &1, release)

  @spec guarantee(Bracket.t(no_return)) :: (Bracket.t(x) -> Bracket.t(x)) when x: var
  def guarantee(finalizer), do: &Bracket.guarantee(&1, finalizer)
end

defmodule Cat.Effect.Bracket.Default do
  @spec guarantee(Bracket.t(x), (Bracket.exit_case(x) -> Bracket.t(no_return))) :: Bracket.t(x) when x: var
  def guarantee(tx, finalizer), do:
    Bracket.bracket(Applicative.pure(tx, nil), Fun.const(tx), finalizer)

  @spec uncancelable(Bracket.t(x)) :: Bracket.t(x) when x: var
  def uncancelable(tx), do: Bracket.bracket(tx, &Applicative.pure(tx, &1), fn _ -> :no_return end)
end
