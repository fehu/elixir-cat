defprotocol MonadError do
  @moduledoc """
  MonadError is an `Monad` (=> `Applicative` => `Functor`) that defines
    * `raise(error) :: t(none)`
    * `recover(t(x), (error -> t(x))) :: t(x) when x: var`
  """


  @type t(_x) :: term
  @type error :: any()

  ## Functor ##

  @spec map(t(x), (x -> y)) :: t(y) when x: var, y: var
  def map(tx, f)

  ## Applicative ##

  @spec pure(x) :: t(x) when x: var
  def pure(x)

  @spec ap(t((x -> y)), t(x)) :: t(y) when x: var, y: var
  def ap(tf, tx)

  @spec product(t(x), t(y)) :: t({x, y}) when x: var, y: var
  def product(tx, ty)

  ## Monad ##

  @spec flat_map(t(x), (x -> t(y))) :: t(y) when x: var, y: var
  def flat_map(tx, f)

  ## MonadError ##

  @spec raise(error) :: t(none)
  def raise(error)

  @spec recover(t(x), (error -> t(x))) :: t(x) when x: var
  def recover(tx, f)

end
