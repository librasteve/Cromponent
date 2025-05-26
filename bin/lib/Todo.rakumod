use Cromponent;
use Red:api<2>;

model Todo does Cromponent {
	has UInt   $.id   is serial;
	has Bool() $.done is rw is column = False;
	has Str()  $.data is column is required;

	method LOAD(Str() $id)  { Todo.^load: $id }
	method ADD(*%data)      { Todo.^create: |%data }
	method DELETE           { $.^delete }

	method toggle is accessible {
		$!done = !$!done;
		$.^save
	}

	method RENDER {
		qq:to/END/;
			<tr id="todo-<.id>">
				<td>
					<label class="todo-toggle">
						<input
							type="checkbox"
							<?.done> checked </?>
							hx-get="./todo/<.id>/toggle"
							hx-target="closest tr"
							hx-swap="outerHTML"
						>
						<span class="custom-checkbox">
						</span>
					</label>
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
