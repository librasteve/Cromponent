use Cromponent;
use Cromponent::Traits;

class Start does Cromponent is macro {
	method RENDER {
		Q:to/END/;
		<:use Head>

		<html>
			<&Head(:!htmx)>
			<body>
				<:body>
			</body>
		</html>
		END
	}
}

sub EXPORT() { Start.^exports }
