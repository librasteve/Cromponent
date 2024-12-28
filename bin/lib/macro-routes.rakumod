#!/usr/bin/env raku

use Cro::HTTP::Router;
use Cromponent;

my UInt $next = 1;

class Start {
	method RENDER {
		Q:to/END/;
		<html>
			<&Head-new(:htmx)>
			<body>
				<:body>
			</body>
		</html>
		END
	}
}

class Head {
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
}

class Header {
	has UInt $.num where {$_ <= 6} = 1;

	method RENDER {
		Q:to/END/
		<h<.num>>
			<:body>
		</h>
		END
	}
}

sub macro-routes is export {
	route {
		add-component Start, :macro;
		add-component Head;
		add-component Header, :macro;
		get  -> {
			template-with-components Q:to/END/;
			<|Start>
				<|Header-new(:num(2))>Test</|>
			</|>
			END
		}
	}
}
