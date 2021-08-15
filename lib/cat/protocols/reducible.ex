defprotocol Cat.Reducible do
  @type t(_x) :: term

  @spec reduce_left(t(x), (x, x -> x)) :: x when x: var
  def reduce_left(tx, f)

  # @spec reduce_right(t(x), ({x, x} -> x)) :: x when x: var
  # def reduce_right(tx, f)

  # @spec reduce_unordered(t(x), (x, x -> x)) :: x when x: var
  # def reduce_unordered(tx, f)
end
