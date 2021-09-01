alias Test.Gen

defmodule Cat.Laws.Law do
  @moduledoc false

  @type eq?(a) :: {a, a}

  @spec eq?(a, a) :: eq?(a) when a: var
  def eq?(x, y), do: {x, y}

  @default_check_tries 100
  @typep check_opt :: {:checks, pos_integer}
  @spec check(
          Gen.t(a),
          (a -> eq?(b)),
          (eq?(b) -> :passed | {:failed, any}),
          [check_opt]
        ) :: {:passed | :failed, String.t} when a: var, b: var
  def check(arg_gen, law, test_eq \\ &default_test_eq/1, opts \\ []) do
    do_check = fn i ->
      with {:ok, arg} <- Gen.sample(arg_gen),
           :passed    <- test_eq.(law.(arg))
        do
          :passed
        else
          {:failed, error} -> {:failed, "Falsified at #{nth(i)} attempt: #{error}"}
          {:error, error}  -> {:error, "Error at #{nth(i)} attempt: #{error}"}
        end
      end
    checks = Keyword.get(opts, :checks, @default_check_tries)
    result =
      1..checks
      |> Stream.map(do_check)
      |> Stream.drop_while(&(&1 == :passed))
      |> Enum.take(1)

    case result do
      []           -> {:passed, "All #{checks} checks have passed."}
      [{_, error}] -> {:failed, error}
    end
  end

  @spec default_test_eq(eq?(any)) :: :passed | {:failed, String.t}
  def default_test_eq({x, y}), do:
    if x == y, do: :passed, else: {:failed, "Mismatch!\nLeft:  #{inspect(x)}\nRight: #{inspect(y)}"}

  # TODO: move?
  @spec nth(pos_integer) :: String.t
  defp nth(1), do: "1st"
  defp nth(2), do: "2nd"
  defp nth(3), do: "3rd"
  defp nth(n), do: "#{n}th"
end
