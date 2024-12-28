use Cromponent;

unit class Start is macro;

method RENDER {
	Q:to/END/;
	<:use Head>
	<html>
		<&Head(:htmx)>
		<body>
			<:body>
		</body>
	</html>
	END
}
