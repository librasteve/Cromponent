use Cromponent;
use Tag;
use Cell;
use Row;

unit class Table does Tag is cromponent;

has Str() $.theme;
has Str() $.head-theme;
has Str() $.body-theme;
has Str() $.foot-theme;
has Row() @.head;
has Row() @.body;
has Row() @.foot;

submethod BUILD(:@head, :@body, :@foot) {
	for @head <-> $row {
		next if $row ~~ Row;
		for $row[] <-> $cell {
			next if $cell ~~ Cell;
			$cell = Cell.new: $cell, :header, :scope<col>
		}
	}
	@!head = @head;
	for @body <-> $row {
		next if $row ~~ Row;
		next if $row.head ~~ Cell;
		$row[0] = Cell.new: $row.head, :header, :scope<row>
	}
	@!body = @body;
	for @foot <-> $row {
		next if $row ~~ Row;
		next if $row.head ~~ Cell;
		$row[0] = Cell.new: $row.head, :header, :scope<row>
	}
	@!foot = @foot;
}

method RENDER {
	q:c:to/END/;
	<table
		<?.theme>data-theme=<.theme></?>
		{ $.arguments }
	>
		<thead
			<?.head-theme>data-theme=<.head-theme></?>
		>
			<@.head>
				<&Row($_)>
			</@>
		</thead>
		<tbody
			<?.body-theme>data-theme=<.body-theme></?>
		>
			<@.body>
				<&Row($_)>
			</@>
		</tbody>
		<tfoot
			<?.foot-theme>data-theme=<.foot-theme></?>
		>
			<@.foot>
				<&Row($_)>
			</@>
		</tfoot>
	</table>
	END
}
