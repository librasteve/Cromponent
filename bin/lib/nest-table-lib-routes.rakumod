use Cro::HTTP::Router;

use Cromponent;
use MyLib;

sub nest-table-lib-routes is export {
	route {
		my $table = MyTable.new: [[1,2],[3,4]];
		add-components MyTable, Row, Cell;

		get  -> {
			template-with-components Q:to/END/, { :$table };
			<html>
				<head>
					<script src="https://unpkg.com/htmx.org@2.0.3" integrity="sha384-0895/pl2MU10Hqc6jd4RvrthNlDiE9U1tWmX7WRESftEDRosgxNsQG/Ze9YMRzHq" crossorigin="anonymous"></script>
				</head>
				<body>
					<&MyTable(.table)>
				</body>
			</html>
			END
		}
	}
}
