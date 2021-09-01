alias Cat.Monad

defmodule Test.Gen do
  @moduledoc false

  @typep rnd_state :: term
  @typep gen_intents :: pos_integer

  @enforce_keys [:do]
  defstruct [:do]
  @type t(a) :: %__MODULE__{do: (rnd_state -> {a | nil, rnd_state})}

  # # Basic Constructors # #

  @spec new((rnd_state -> {a | nil, rnd_state})) :: t(a) when a: var
  def new(f), do: %__MODULE__{do: f}

  @spec const(a) :: t(a) when a: var
  def const(a), do: new fn s -> {a, s} end

  @spec delayed((-> a | nil)) :: t(a) when a: var
  def delayed(fa), do: new fn s -> {fa.(), s} end

  defmacro delay(a) do
    [s] = Macro.generate_arguments(1, __MODULE__)
    quote do: new fn unquote(s) -> {unquote(a), unquote(s)} end
  end

  # # Default Constructors # #
  @max_int 4_294_967_296
  @max_float_exp 2046
  @max_float_mantissa 4_503_599_627_370_495

  @typep distribution :: :normal | :uniform

  @typep float_opt :: {:min, float} | {:max, float}

  @spec non_neg_float(distribution, [float_opt]) :: t(float)
  def non_neg_float(dist \\ :normal, opts \\ []) do
    {min, max} = extract_min_max(opts, 0, max_float())
    scale = (max - min) / max
    gen = case dist do
      :normal -> &:rand.normal_s/1
      :uniform -> &:rand.uniform_s/1
    end
    new fn rnd_state ->
      {rnd, new_state} = gen.(rnd_state)
      {min + rnd * scale, new_state}
    end
  end

  @typep non_neg_int_opt :: {:min, non_neg_integer} | {:max, non_neg_integer}
  @spec non_neg_int([non_neg_int_opt]) :: t(non_neg_integer)
  def non_neg_int(opts \\ []) do
    {min, max} = extract_min_max(opts, 0, @max_int)
    diff = max - min
    new fn rnd_state ->
      {rnd, new_state} = :rand.uniform_s(diff, rnd_state)
      {min + rnd, new_state}
    end
  end

  @spec list(t(a), length: pos_integer) :: t([a]) when a: var
  def list(%__MODULE__{do: gen}, length: length), do:
    new fn rnd_state ->
      Enum.reduce 1..length, {[], rnd_state}, fn _, {acc, state} ->
        {v, new_state} = gen.(state)
        {[v | acc], new_state}
      end
    end

  @default_list_max_length 100
  @typep list_opt :: {:min, non_neg_integer} | {:max, non_neg_integer}
  @spec list(t(a), [list_opt]) :: t([a]) when a: var
  def list(gen, opts) do
    {min, max} = extract_min_max(opts, 0, @default_list_max_length)
    Monad.flat_map non_neg_int(min: min, max: max), &list(gen, length: &1)
  end
  def list(gen), do: list(gen, [])

  @spec extract_min_max(keyword, a, a) :: {a, a} when a: var
  defp extract_min_max(opts, min0, max0) do
    min = Keyword.get(opts, :min, min0)
    if min < min0, do: raise "min (#{min}) < #{min0}"
    max = Keyword.get(opts, :max, max0)
    if min >= max, do: raise "min (#{min}) >= max (#{max})"
    {min, max}
  end

  # # Ops # #

  @spec filter(t(a), (a -> boolean)) :: t(a) when a: var
  def filter(%__MODULE__{do: gen}, pred), do:
    new fn rnd_state ->
      a = gen.(rnd_state)
      if pred.(a), do: a, else: nil
    end

  @spec generate(t(a), rnd_state) :: a | nil when a: var
  def generate(%__MODULE__{do: gen}, rnd_state), do: elem gen.(rnd_state), 0

  @default_intents 100
  @spec sample(t(a), gen_intents, (-> rnd_state)) :: {:ok, a} | {:error, {:cannot_generate, t(a)}} when a: var
  def sample(gen, intents \\ @default_intents, rand_f \\ fn -> :rand.seed(:default) end)
  def sample(gen, 0, _), do:
    {:error, {:cannot_generate, gen}}
  def sample(gen, intents, rand_f) do
    attempt = generate(gen, rand_f.())
    if attempt,
       do: {:ok, attempt},
       else: sample(gen, intents - 1, rand_f)
  end

  defp max_float() do
    <<float::float>> = <<0::1, @max_float_exp::11, @max_float_mantissa::52>>
    float
  end

end

alias Cat.{Applicative, Functor}
alias Test.Gen

defimpl Functor, for: Gen do
  @spec map(Gen.t(a), (a -> b)) :: Gen.t(b) when a: var, b: var
  def map(%Gen{do: gen}, f), do: Gen.new fn rnd_state ->
    {a, new_state} = gen.(rnd_state)
    {f.(a), new_state}
  end

  @spec as(Gen.t(any), a) :: Gen.t(a) when a: var
  defdelegate as(t, a), to: Functor.Default
end

defimpl Applicative, for: Gen do
  @spec pure(Gen.t(any), a) :: Gen.t(a) when a: var
  def pure(_, a), do: Gen.const(a)

  @spec ap(Gen.t((a -> b)), Gen.t(a)) :: Gen.t(b) when a: var, b: var
  defdelegate ap(tf, ta), to: Applicative.Default.FromMonad

  @spec product(Gen.t(a), Gen.t(b)) :: Gen.t({a, b}) when a: var, b: var
  defdelegate product(ta, tb), to: Applicative.Default

  @spec product_l(Gen.t(a), Gen.t(any)) :: Gen.t(a) when a: var
  defdelegate product_l(ta, tb), to: Applicative.Default

  @spec product_r(Gen.t(any), Gen.t(b)) :: Gen.t(b) when b: var
  defdelegate product_r(ta, tb), to: Applicative.Default

  @spec map2(Gen.t(a), Gen.t(b), (a, b -> c)) :: Gen.t(c) when a: var, b: var, c: var
  defdelegate map2(ta, tb, f), to: Applicative.Default
end

defimpl Monad, for: Gen do
  @spec flat_map(Gen.t(a), (a -> Gen.t(b))) :: Gen.t(b) when a: var, b: var
  def flat_map(%Gen{do: gen}, f), do:
     Gen.new fn rnd_state ->
       {a, new_state} = gen.(rnd_state)
       Map.get(f.(a), :do).(new_state)
     end

  @spec flat_tap(Gen.t(a), (a -> Gen.t(no_return))) :: Gen.t(a) when a: var
  defdelegate flat_tap(ta, f), to: Monad.Default

  @spec flatten(Gen.t(Gen.t(a))) :: Gen.t(a) when a: var
  defdelegate flatten(tta), to: Monad.Default
end
