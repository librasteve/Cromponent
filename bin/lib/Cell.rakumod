use Cromponent;
use Tag;

class Cell does Cromponent does Tag {
	has Str() $.scope;
	has Str() $.value;
	has Bool  $.header = False;

	multi method new(Str $value, *%pars) {
		self.new: :$value, |%pars
	}

	method RENDER {
		q:c:to/END/;
		<?.header>
			<th
				<?.scope>scope=<.scope></?>
				{ $.arguments // "" }
			>
				<?.value><.value></?>
			</th>
		</?>
		<!>
			<td { $.arguments // "" }>
				<?.value><.value></?>
			</td>
		</!>
		END
	}
}

sub EXPORT() { Cell.^exports }
