defprotocol Cat.Reducible do
  @type t(_x) :: term

  @spec reduce_left(t(a), (a, a -> a)) :: a when a: var
  def reduce_left(ta, f)

  # @spec reduce_right(t(a), ({a, a} -> a)) :: a when a: var
  # def reduce_right(ta, f)

  # @spec reduce_unordered(t(a), (a, a -> a)) :: a when a: var
  # def reduce_unordered(ta, f)
end
