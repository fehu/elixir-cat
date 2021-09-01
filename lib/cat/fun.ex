defmodule Cat.Fun do
  @moduledoc false

  defmacro id do
    [arg] = Macro.generate_arguments(1, nil)
    quote do: fn unquote(arg) -> unquote(arg) end
  end

  defmacro const(x) do
    [tmp] = Macro.generate_arguments(1, nil)
    quote do
      unquote(tmp) = unquote(x)
      fn _ -> unquote(tmp) end
    end
  end

  defmacro const_inline(x) do
    quote do: fn _ -> unquote(x) end
  end

  defmacro tupled(f) do
    [a1, a2, a3, a4, a5] = Macro.generate_arguments(5, __MODULE__)
    quote do: fn
      {unquote(a1), unquote(a2), unquote(a3), unquote(a4), unquote(a5)} ->
        unquote(f).(unquote(a1), unquote(a2), unquote(a3), unquote(a4), unquote(a5))
      {unquote(a1), unquote(a2), unquote(a3), unquote(a4)} ->
        unquote(f).(unquote(a1), unquote(a2), unquote(a3), unquote(a4))
      {unquote(a1), unquote(a2), unquote(a3)} ->
        unquote(f).(unquote(a1), unquote(a2), unquote(a3))
      {unquote(a1), unquote(a2)} ->
        unquote(f).(unquote(a1), unquote(a2))
      unquote(a1) ->
        unquote(f).(unquote(a1))
    end
  end

  # `f . g` === `fn x -> f(g(x))`
  defmacro compose(f, g) do
    [arg] = Macro.generate_arguments(1, __MODULE__)
    quote do
      fn unquote(arg) -> unquote(f).(unquote(g).(unquote(arg))) end
    end
  end
end
