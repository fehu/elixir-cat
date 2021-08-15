defprotocol Foldable do
  @type t(_x) :: term

  @spec fold_left(t(x), y, (y, x -> y)) :: y when x: var, y: var
  def fold_left(tx, zero, f)

#  @spec fold_right(t(x), y, ({x, y} -> y)) :: y when x: var, y: var
#  def fold_right(tx, zero, f)
end

defimpl Foldable, for: List do
  @type t(x) :: [x]

  @spec fold_left([x], y, (y, x -> y)) :: y when x: var, y: var
  def fold_left([h | t], acc, f), do: fold_left(t, f.(acc, h), f)
  def fold_left([], acc, _),      do: acc

#  @spec fold_right([x], y, ({x, y} -> y)) :: y when x: var, y: var
#  def fold_right(tx, zero, f)

end
