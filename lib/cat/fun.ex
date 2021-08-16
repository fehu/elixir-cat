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

end
