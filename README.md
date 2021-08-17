# Cat

**Category Theory Abstractions**

Inspired by [cats](http://typelevel.org/cats/) library in Scala. 

## Monadic Syntax

Macro [`Syntax.monadic`](lib/cat/syntax/syntax.ex) rewrites `with` clauses
to nested `Functor.map` and `Monad.flat_map` applications.
If clause has `else` expression, it's mapped to ``MonadError.recover`.

```elixir
Syntax.monadic do
  with a <- Either.right(1),
       _ = IO.puts("x1 = #{a}"),
       b <- Either.left("!"),
       _ = IO.puts("b = #{b}")
    do a + b
  else
    failure ->
      IO.puts(failure)
      Either.right("-")
  end
end
```
Is [rewritten](test/syntax_monadic_test.exs) to
```elixir
MonadError.recover(Monad.flat_map(Either.right(1), fn a ->
  IO.puts("x1 = \#{a}")
  Functor.map(Either.left("!"), fn b ->
    IO.puts("b = \#{b}")
    a + b
  end)
end), fn failure ->
  IO.puts(failure)
  Either.right("-")
end)
```

## Protocols

[Delegates](lib/cat/cat.ex)

-----

* [Functor](lib/cat/protocols/functor.ex)
* [Applicative](lib/cat/protocols/applicative.ex)
* [Monad](lib/cat/protocols/monad.ex)
* [MonadError](lib/cat/protocols/monad_error.ex)
-----
* [Semigroup](lib/cat/protocols/semigroup.ex)
* [Monoid.ex](lib/cat/protocols/monoid.ex)
-----
* [Reducible](lib/cat/protocols/reducible.ex)
* [Foldable](lib/cat/protocols/foldable.ex)

## Data

* [Maybe](lib/cat/data/maybe.ex)
* [Either](lib/cat/data/either.ex)
