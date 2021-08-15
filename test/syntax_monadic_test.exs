defmodule SyntaxMonadicTest do
  use ExUnit.Case

  require Syntax

  test "convert `with` expressions to nested `Monad.flat_map` and `Functor`.map" do
    expr = quote do
      Syntax.monadic do
        with x <- Either.right(1),
             _ = IO.puts("x = #{x}"),
             y <- Either.left("!"),
             _ = IO.puts("y = #{y}"),
             do: x + y
      end
    end
    expected =
      """
      Monad.flat_map(Either.right(1), fn x ->
        IO.puts(\"x = \#{x}\")
        Functor.map(Either.left(\"!\"), fn y ->
          IO.puts(\"y = \#{y}\")
          x + y
        end)
      end)\
      """
    assert show_code(expr) == expected
  end

  test "convert `with` expressions with `else` clause to `MonadError.recover`" do
    expr = quote do
      Syntax.monadic do
        with x <- Either.right(1),
             _ = IO.puts("x1 = #{x}"),
             y <- Either.left("!"),
             _ = IO.puts("y = #{y}")
          do x + y
        else
          failure ->
            IO.puts(failure)
            Either.right("-")
        end
      end
    end
    expected =
      """
      MonadError.recover(Monad.flat_map(Either.right(1), fn x ->
        IO.puts("x1 = \#{x}")
        Functor.map(Either.left("!"), fn y ->
          IO.puts("y = \#{y}")
          x + y
        end)
      end), fn failure ->
        IO.puts(failure)
        Either.right("-")
      end)\
      """
    assert show_code(expr) == expected
  end

  defp show_code(expr), do: Macro.to_string(Macro.expand(expr, __ENV__))
end
