defmodule SyntaxMonadicTest do
  use ExUnit.Case

  alias Cat.{Result, Syntax}
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
      Cat.Monad.flat_map(Either.right(1), fn x ->
        IO.puts(\"x = \#{x}\")
        Cat.Functor.map(Either.left(\"!\"), fn y ->
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
        with x <- Result.lift({:ok, 1}),
             _ = IO.puts("x = #{x}"),
             y <- Result.fail("!"),
             _ = IO.puts("y = #{y}")
          do x + y
        else
          failures ->
            Enum.each(failures, &(IO.inspect(&1)))
            Result.ok("-")
        end
      end
    end
    expected =
      """
      Cat.MonadError.recover(Cat.Monad.flat_map(Result.lift({:ok, 1}), fn x ->
        IO.puts("x = \#{x}")
        Cat.Functor.map(Result.fail("!"), fn y ->
          IO.puts("y = \#{y}")
          x + y
        end)
      end), fn failures ->
        Enum.each(failures, &(IO.inspect(&1)))
        Result.ok("-")
      end)\
      """
    assert show_code(expr) == expected
  end

  defp show_code(expr), do: Macro.to_string(Macro.expand(expr, __ENV__))
end
