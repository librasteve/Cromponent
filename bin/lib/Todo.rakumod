use Cromponent;

my UInt $next = 1;
class Todo does Cromponent {
	my @todos = do for <blablabla blebleble> -> $data { Todo.new: :$data }
	has UInt() $.id = $next++;
	has Bool() $.done is rw = False;
	has Str()  $.data is required;

	method LOAD(UInt() $id) { @todos.first: { .id == $id } }
	method CREATE(*%data)   { @todos.push: my $n = self.new: |%data; $n }
	method DELETE           { @todos .= grep: { .id != $!id } }

	method all { @todos }

	method toggle is accessible {
		$!done = !$!done
	}

	method RENDER {
		qq:to/END/;
			<tr>
				<td>
					<input
						type=checkbox
						<?.done> checked </?>
						hx-get="./todo/<.id>/toggle"
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
						hx-delete="./todo/<.id>"
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

sub EXPORT() {
	Todo.^exports
}
