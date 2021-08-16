defmodule Cat.Syntax do
  @moduledoc false

  defmacro monadic(do: {:with, _line, args}) do
    %{else: else_, expr: monadic_expr} =
      args
        |> Enum.reverse
        |> Enum.reduce(%{else: nil, expr: nil}, fn
              list=[_|_], %{else: nil, expr: nil} ->
                %{
                  op: :map,
                  expr: Keyword.get(list, :do),
                  else: Keyword.get(list, :else)
                 }
              {:<-, _, [{var, _, ctx}, val]}, acc ->
                %{acc | :expr => monadic_expr(var, ctx, val, acc.op, acc.expr),
                        :op => :flat_map
                 }
              {:=, _, [{var, _, ctx}, val]}, acc ->
                %{acc | :expr => assign_expr(var, ctx, val, acc.expr)}
          end)
    case else_ do
      nil -> monadic_expr
      f   -> quote do: Cat.MonadError.recover(unquote(monadic_expr), unquote(mk_fun(f)))
    end
  end

  @typep monadic_op :: :map | :flat_map

  @spec monadic_expr(var :: atom, ctx :: atom, val :: Macro.output, op :: monadic_op, arg :: Macro.output) :: Macro.output
  defp monadic_expr(var, ctx, val, op, arg) do
    f_expr = quote do: fn unquote(Macro.var(var, ctx)) -> unquote(arg) end
    case op do
      :map      -> quote do: Cat.Functor.map(unquote(val), unquote(f_expr))
      :flat_map -> quote do: Cat.Monad.flat_map(unquote(val), unquote(f_expr))
    end
  end

  @spec assign_expr(var :: atom, ctx :: atom, val :: Macro.t(), arg :: Macro.output) :: Macro.output
  defp assign_expr(var, ctx, val, arg) do
    arg_exprs = case arg do
      {:__block__, _, exprs} -> exprs
      expr                   -> [expr]
    end
    var_expr = case var do
      :_ -> val
      _  -> quote do: unquote(Macro.var(var, ctx)) = unquote(val)
    end
    quote do
      unquote(var_expr)
      unquote_splicing(arg_exprs)
    end
  end

  @spec mk_fun(list(Macro.input)) :: Macro.output
  defp mk_fun(cases0) do
    pre = fn
      {name, [line: _], ctx}, acc when is_atom(name) and is_atom(ctx) -> {Macro.var(name, ctx), acc}
      tree, acc -> {tree, acc}
    end
    post = fn tree, acc -> {tree, acc} end
    {cases, _} = Macro.traverse(cases0, nil, pre, post)
    {:fn, [], cases}
  end

end
