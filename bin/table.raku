#!/usr/bin/env raku

use lib "lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cromponent;

my UInt $next = 1;

class Tag {
	has @.classes;
	has $.id;

	method arguments {
		q:to/END/
		<?.classes>class=<@.classes><$_></@></?>
		<?.id>id=<.id></?>
		END
	}
}
class Header is Tag {
	has Str() $.value;

	method RENDER {
		q:c:to/END/;
		<th
			scope="<.scope>"
			{ $.arguments }
		>
			<.value>
		</th>
		END
	}
}
class Cell is Tag {
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
				scope=<.scope>
				{ $.arguments }
			>
				<.value>
			</th>
		</?>
		<!>
			<td
				{ $.arguments }
			>
				<.value>
			</td>
		</!>
		END
	}
}

class Row is Tag {
	has Cell() @.cells;

	multi method new(@cells, *%pars) {
		self.new: :@cells, |%pars
	}

	method RENDER {
		q:c:to/END/;
		<tr
			{ $.arguments }
		>
		<@.cells>
			<&Cell($_)>
		</@>
		</tr>
		END
	}
}
class Table is Tag {
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
}

my $routes = route {
	add-components Table, Header, Cell, Row;
	my $table = Table.new:
		:head[["Planet", "Fiameter (km)", "Distance to Sun (AU)", "Orbit (days)"],],
		:body[
			["Mercury", "4,880" , "0.39", "88" ],
			["Venus"  , "12,104", "0.72", "225"],
			["Earth"  , "12,742", "1.00", "365"],
			["Mars"   , "6,779" , "1.52", "687"],
		],
		:foot[["Average", "9,126", "0.91", "341"],]
	;

	my $themed  = $table.clone: :head-theme<light>;
	my $striped = $table.clone: :classes<striped>;

	my $tables = {
		:tables[
			{ :tags<a e i o u>, :table($table),  },
			{ :tags<a e i o u>, :table($themed), },
			{ :tags<a e i o u>, :table($striped),},
		],
	};
	get  -> {
		template-with-components Q:to/END/, $tables;
		<html>
			<head>
				<link
				  rel="stylesheet"
				  href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"
				>
			</head>
			<body>
				<@tables>
					<ul>
						<@tags><li><$_></li></@>
					</ul>
					<&Table(.table)>
					<:separator><br><hr><br></:>
				</@>
			</body>
		</html>
		END
	}
}
my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => "0.0.0.0",
    port => 3000,
    application => $routes,
);
$http.start;
say "Listening at http://0.0.0.0:3000";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}

