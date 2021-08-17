defprotocol Cat.Foldable do
  @type t(_x) :: term

  @spec fold_left(t(a), b, (b, a -> b)) :: b when a: var, b: var
  def fold_left(ta, zero, f)

#  @spec fold_right(t(a), b, ({a, b} -> b)) :: b when a: var, b: var
#  def fold_right(ta, zero, f)
end

alias Cat.Foldable

defimpl Foldable, for: List do
  @type t(a) :: [a]

  @spec fold_left([a], b, (b, a -> b)) :: b when a: var, b: var
  def fold_left([h | t], acc, f), do: fold_left(t, f.(acc, h), f)
  def fold_left([], acc, _),      do: acc

#  @spec fold_right([a], b, ({a, b} -> b)) :: b when a: var, b: var
#  def fold_right(ta, zero, f)

end
