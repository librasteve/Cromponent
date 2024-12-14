use Cromponent;

my @manifest = <MyTable Row Cell Grid Item>;

class Cell is export {
	has $.data is required;
	
	multi method new($data) {
		$.new: :$data
	}

	method RENDER {
		q:to/END/
			<td><.data></td>
		END
	}
}

class Row is export {
	has Cell() @.cells is required;
	
	multi method new(@cells) {
		$.new: :@cells
	}

	method RENDER {
		q:to/END/
			<tr>
				<@.cells: $c>
					<&Cell($c)>
				</@>
			</tr>
		END
	}
}

class MyTable is export {
	has Row() @.rows is required;
	
	multi method new(@rows) {
		$.new: :@rows
	}

	method RENDER {
		q:to/END/
			<table border=1>
				<@.rows: $r>
					<&Row($r)>
				</@>
			</table>
		END
	}
}

role Typography {
	method typography {
		q:to/END/
			.grid-item {
				font-size: 16px;
			}
		END
	}
}

role Color {
	method color {
		q:to/END/
			.grid-item {
				background-color: #4CAF50;
				color: white;
			}
		END
	}
}

role Decoration {
	method decoration {
		q:to/END/
			.grid-item {
				border: 1px solid #ddd;
				padding: 20px;
			}
		END
	}
}

role Style {
	also does Typography;
	also does Color;
	also does Decoration;

	method style {
		'<style>' ~
			$.typography ~
			$.color ~
			$.decoration  ~
		'</style>'
	}
}

class Item does Style is export {
	has $.data is required;

	multi method new($data) {
		$.new: :$data
	}

	#iamerejh
	method style2 {
		q:to/END/
		<style>
			.grid-item {
				background-color: #4CAF50;
				color: white;
				#border: 1px solid #ddd;
				#padding: 20px;
				text-align: center;
				font-size: 16px;
			}
		</style>
		END
	}

	method RENDER {
		$.style ~
		q:to/END/
			<div class="grid-item"><.data></div>
		END
	}
}

class Grid is export {
	has Item() @.items is required;

	multi method new(@items) {
		$.new: :@items
	}

	method style {
		q:to/END/
		<style>
			.grid-container {
				display: grid;
				grid-template-columns: 1fr 1fr 1fr; /* Creates 3 equal columns */
				gap: 10px; /* Adds space between grid items */
				padding: 10px;
				background-color: #f2f2f2;
			}
		</style>
		END
	}

	method RENDER {
		$.style ~
		q:to/END/
		<div class="grid-container">
			<@.items: $i>
				<&Item($i)>
			</@>
		</div>
		END
	}
}


##### HTML Functional Export #####

# put in all the tags programmatically
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {
	for @manifest -> $name {

		my $label = $name.lc;

		OUR::{'&' ~ $label} :=

			sub (*@a, :$topic! is rw, *%h) {

				$topic{$label} = ::($name).new( |@a, |%h );
				'<&' ~ $name ~ '(.' ~ $label ~ ')>';

			}
	}
}
