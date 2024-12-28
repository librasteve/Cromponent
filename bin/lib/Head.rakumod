use Cromponent;

unit class Head is cromponent;

has Bool $.htmx = False;

method RENDER {
	Q:to/END/
	<head>
		<?.htmx>
		<script src="https://unpkg.com/htmx.org@2.0.3" integrity="sha384-0895/pl2MU10Hqc6jd4RvrthNlDiE9U1tWmX7WRESftEDRosgxNsQG/Ze9YMRzHq" crossorigin="anonymous"></script>
		</?>
	</head>
	END
}
