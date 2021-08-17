defprotocol Cat.Effect.Bracket do
  @moduledoc """
  Resource management & basic cancellation.

  Bracket defines
    * `bracket(acquire: t(a), use: (a -> t(b)), release: (exit_case(a) -> t(no_return))) :: t(b)`
    * `guarantee(t(a), (exit_case(a) -> t(no_return))) :: t(a)`
    * `uncancelable(t(a)) :: t(a)`

  **It must also be `MonadError, `Monad`, `Applicative` and `Functor`.**

  Default implementations (at `Bracket.Default`):
    * `guarantee(t(a), always: t(no_return)) :: t(a)`
  """

  @type t(_x) :: term

  @type exit_case(a) :: {:ok, a} | {:error, any} | :canceled

  @spec bracket(t(a), (a -> t(b)), (exit_case(a) -> t(no_return))) :: t(b) when a: var, b: var
  def bracket(acquire, use, release)

  @spec guarantee(t(a), (exit_case(a) -> t(no_return))) :: t(a) when a: var
  def guarantee(ta, finalizer)

  @spec uncancelable(t(a)) :: t(a) when a: var
  def uncancelable(ta)
end

alias Cat.Applicative
alias Cat.Effect.Bracket
alias Cat.Fun

require Fun

defmodule Cat.Effect.Bracket.Arrow do
  @type use(a, b) :: (a -> Bracket.t(b))

  @spec bracket(
          acquire: Bracket.t(a),
          release: (Bracket.exit_case(a) -> Bracket.t(no_return))
        ) :: (use(a, b) -> Bracket.t(b)) when a: var, b: var
  def bracket(acquire: acquire, release: release), do: &Bracket.bracket(acquire, &1, release)

  @spec guarantee(Bracket.t(no_return)) :: (Bracket.t(a) -> Bracket.t(a)) when a: var
  def guarantee(finalizer), do: &Bracket.guarantee(&1, finalizer)
end

defmodule Cat.Effect.Bracket.Default do
  @spec guarantee(Bracket.t(a), (Bracket.exit_case(a) -> Bracket.t(no_return))) :: Bracket.t(a) when a: var
  def guarantee(ta, finalizer), do:
    Bracket.bracket(Applicative.pure(ta, nil), Fun.const(ta), finalizer)

  @spec uncancelable(Bracket.t(a)) :: Bracket.t(a) when a: var
  def uncancelable(ta), do: Bracket.bracket(ta, &Applicative.pure(ta, &1), fn _ -> :no_return end)
end
