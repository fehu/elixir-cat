# Cat

**Category Theory Abstractions**

Inspired by [cats](http://typelevel.org/cats/) library in Scala. 

## Monadic Syntax

Macro [`Syntax.monadic`](lib/cat/syntax/syntax.ex) rewrites `with` clauses
to nested `Functor.map` and `Monad.flat_map` applications.
If clause has `else` expression, it's mapped to ``MonadError.recover`.

```elixir
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
```
Is [rewritten](test/syntax_monadic_test.exs) to
```elixir
MonadError.recover(Monad.flat_map(Either.right(1), fn x ->
  IO.puts("x1 = \#{x}")
  Functor.map(Either.left("!"), fn y ->
    IO.puts("y = \#{y}")
    x + y
  end)
end), fn failure ->
  IO.puts(failure)
  Either.right("-")
end)
```

## Protocols

* [Functor](lib/cat/protocols/functor.ex)
* [Applicative](lib/cat/protocols/applicative.ex)
* [Monad](lib/cat/protocols/monad.ex)
* [MonadError](lib/cat/protocols/monad_error.ex)
-----
* [Semigroup](lib/cat/protocols/semigroup.ex)
* [~Monoid.ex~](lib/cat/protocols/monoid.ex)
-----
* [Reducible](lib/cat/protocols/reducible.ex)
* [Foldable](lib/cat/protocols/foldable.ex)

## Data
* [Maybe](lib/cat/data/maybe.ex)
* [Either](lib/cat/data/either.ex)
