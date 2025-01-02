use Cromponent;
use Tag;
use Cell;

class Row does Cromponent does Tag {
	has Cell() @.cells;

	multi method new(@cells, *%pars) {
		self.new: :@cells, |%pars
	}

	method RENDER {
		q:c:to/END/;
		<tr
			{ $.arguments // "" }
		>
		<@.cells>
			<&HTML($_)>
		</@>
		</tr>
		END
	}
}

sub EXPORT() { Row.^exports }
