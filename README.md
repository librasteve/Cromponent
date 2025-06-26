[![Actions Status](https://github.com/FCO/Cromponent/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Cromponent/actions)

NAME
====

Cromponent - A way create web components with cro templates

SYNOPSIS
========

```raku
use Cromponent;
class AComponent does Cromponent {
	has $.data;

	method RENDER {
		Q:to/END/
		<h1><.data></h1>
		END
	}
}

sub EXPORT { AComponent.^exports }
```

DESCRIPTION
===========

Cromponent is a way create web components with cro templates

You can use Cromponents in 3 distinct (and complementar) ways

  * In a template only way: If wou just want your Cromponent to be a "fancy substitute for cro-template sub/macro", You can simpley create your Cromponent, and on yout template, <:use> it, it with export a sub (or a macro if you used the `is macro` trait) to your template, that sub (or macro) will accept any arguments you pass it and will pass it to your Cromponent's conscructor (new), and use the result of that as the value to be used.

    Ex:

    ```raku
    use Cromponent;
    use Cromponent::Traits;

    class H1 does Cromponent is macro {
	    has Str $.prefix = "My fancy H1";

	    method RENDER {
		    Q[<h1><.prefix><:body></h1>]
	    }
    }

    sub EXPORT { H1.^exports }
    ```

    On your template:

    ```crotmp
    <:use H1>
    <|H1(:prefix('Something very important: '))>
	    That was it
    </|>
    ```

  * As a value passed as data to the template. If a Cromponent is passed as a value to a template, you can simply "print" it inside the template to have its rendered version, it will probably be an HTML, so it will need to be called inside a <&HTML()> call (I'm still trying to figureout how to avoid that requirement).

    Ex:

    ```raku
    use Cromponent;

    class Todo does Cromponent {
	    has Str  $.text is required;
	    has Bool &.done = False;

	    method RENDER {
		    Q:to/END/
		    <tr>
			    <td>
				    <input type='checkbox' <?.done>checked</?>>
			    </td>
			    <td>
				    <.text>
			    </td>
		    </tr>
		    END
	    }
    }

    sub EXPORT { Todo.^exports }
    ```

    On your route:

    ```raku
    template "todos.crotmp", { :todos(<bla ble bli>.map: -> $text { Todo.new: :$text }) }
    ```

    On your template:

    ```crotmp
    <@.todos: $todo>
	    <&HTML($todo)>
    </@>
    ```

  * You can also use a Cromponent to auto-generate cro routes

    Ex:

    ```raku
    use Cromponent;
    use Cromponent::Traits;

    class Text does Cromponent {
	    my UInt $next-id = 1;
	    my %texts;

	    has UInt $.id      = $next-id++;
	    has Str  $.text is required;
	    has Bool $.deleted = False;

	    method TWEAK(|) { %tests{$!id} = self }

	    method LOAD($id) { %tests{$id} }

	    method all { %texts.values }

	    method toggle is accessible {
		    $!deleted = !$!deleted
	    }

	    method RENDER {
		    Q:to/END/
		    <?.deleted><del><.text></del></?>
		    <!><.text></!>
		    END
	    }
    }

    sub EXPORT { Todo.^exports }
    ```

    On your route:

    ```raku
    use Text;
    route {
	    Text.^add-cromponent-routes;

	    get -> {
		    template "texts.crotmp", { :texts[ Texts.all ] }
	    }
    }
    ```

    The call to the .^add-cromponent-routes method will create (on this case) 2 endpoints:

      * `/text/<id>` -- that will return the HTML ot the obj with that id rendered (it will use the method `LOAD` to get the object)

      * `/text/<id>/toggle` -- that will load the object using the method `LOAD` and call `toggle` on it

    You can also define the method `ADD`, `DELETE`, and `UPDATE` to allow it to create other endpoints.

AUTHOR
======

Fernando Corrêa de Oliveira <fco@cpan.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

