#!/usr/bin/env raku

use Cro::HTTP::Router;
use Cromponent;

my UInt $next = 1;

class Todo {
	has UInt $.id = $next++;
	has Bool $.done is rw = False;
	has Str  $.data is required;

	method toggle {
		$!done = !$!done
	}

	method RENDER {
		qq:to/END/;
			<tr>
				<td>
					<input
						type=checkbox
						<?.done> checked </?>
						hx-get="/cromponent/todo/<.id>/toggle"
						hx-target="closest tr"
						hx-swap="outerHTML"
					>
				</td>
				<td>
					<?.done>
						<del><.data></del>
					</?>
					<!>
						<.data>
					</!>
				</td>
				<td>
					<button
						hx-delete="/cromponent/todo/<.id>"
						hx-confirm="Are you sure?"
						hx-target="closest tr"
						hx-swap="delete"
					>
						-
					</button>
				</td>
			</tr>
		END
	}
}

sub cromponent-routes is export {
	route {
		my @todos = do for <blablabla blebleble> -> $data { Todo.new: :$data }
		add-component
			Todo,
			:load( -> UInt() $id { @todos.first: { .id == $id } }),
			:create(-> *%data { @todos.push: my $n = Todo.new: |%data; $n }),
			:delete( -> UInt() $id { @todos .= grep: { .id != $id } }),
		;
		get  -> {
			template-with-components Q:to/END/, { :@todos };
			<html>
				<head>
					<script src="https://unpkg.com/htmx.org@2.0.3" integrity="sha384-0895/pl2MU10Hqc6jd4RvrthNlDiE9U1tWmX7WRESftEDRosgxNsQG/Ze9YMRzHq" crossorigin="anonymous"></script>
				</head>
				<body>
					<table>
						<@.todos: $todo>
							<&Todo($todo)>
						</@>
					</table>
					<form
						hx-post="/cromponent/todo"
						hx-target="table"
						hx-swap="beforeend"
						hx-on::after-request="this.reset()"
					>
						<input name=data><button type=submit>+</button>
					</form>
				</body>
			</html>
			END
		}
	}
}
