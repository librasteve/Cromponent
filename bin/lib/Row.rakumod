use Cromponent;
use Tag;
use Cell;

unit class Row is cromponent;

has Cell() @.cells;

multi method new(@cells, *%pars) {
	self.new: :@cells, |%pars
}

method RENDER {
	q:c:to/END/;
	<#:use Cell>
	<tr
		{ $.arguments // "" }
	>
	<@.cells>
		<&Cell($_)>
	</@>
	</tr>
	END
}
