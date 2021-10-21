defmodule Cat.Macros.Common do
  @moduledoc false

  @spec safe(Macro.input, Macro.input, Macro.input) :: Macro.output
  def safe(success, failure, x), do:
    _safe(success, failure, x)

  @spec flat_safe(Macro.input, Macro.input) :: Macro.output
  def flat_safe(failure, x), do:
    _safe(nil, failure, x)

  @spec _safe(Macro.input, Macro.input, Macro.input) :: Macro.output
  defp _safe(success, failure, x) do
    [err] = Macro.generate_arguments(1, __MODULE__)
    expr = case success do
      nil -> x
      _   -> quote do: unquote(success).(unquote(x))
    end
    quote do
      try do
        unquote(expr)
      catch
        :error, unquote(err) -> unquote(failure).(unquote(err))
        :exit, unquote(err)  -> unquote(failure).(unquote(err))
        unquote(err)         -> unquote(failure).(unquote(err))
      end
    end
  end
end
