defmodule SyntaxMonadicTest do
  use ExUnit.Case

  alias Cat.{Either, Result, Syntax}
  require Syntax

  test "convert `with` expressions to nested `Monad.flat_map` and `Functor`.map" do
    expr = quote do
      Syntax.monadic do
        with a <- Either.right(1),
             _ = IO.puts("a = #{a}"),
             b <- Either.left("!"),
             _ = IO.puts("b = #{b}"),
             do: a + b
      end
    end
    expected =
      """
      Cat.Monad.flat_map(Either.right(1), fn a ->
        IO.puts(\"a = \#{a}\")
        Cat.Functor.map(Either.left(\"!\"), fn b ->
          IO.puts(\"b = \#{b}\")
          a + b
        end)
      end)\
      """
    assert show_code(expr) == expected
    assert eval_code(expr) == Either.left("!")
  end

  test "convert `with` expressions with `else` clause to `MonadError.recover`" do
    expr = quote do
      Syntax.monadic do
        with a <- Result.lift({:ok, 1}),
             _ = IO.puts("a = #{a}"),
             b <- Result.fail("!"),
             _ = IO.puts("b = #{b}")
          do a + b
        else
          failures ->
            Enum.each(failures, &(IO.inspect(&1)))
            Result.ok("-")
        end
      end
    end
    expected =
      """
      Cat.MonadError.recover(Cat.Monad.flat_map(Result.lift({:ok, 1}), fn a ->
        IO.puts("a = \#{a}")
        Cat.Functor.map(Result.fail("!"), fn b ->
          IO.puts("b = \#{b}")
          a + b
        end)
      end), fn failures ->
        Enum.each(failures, &(IO.inspect(&1)))
        Result.ok("-")
      end)\
      """
    assert show_code(expr) == expected
    assert eval_code(expr) == Result.ok("-")
  end

  defp show_code(expr), do: Macro.to_string(Macro.expand(expr, __ENV__))
  defp eval_code(expr) do
    {result, _} = Code.eval_quoted(expr, [], __ENV__)
    result
  end
end
