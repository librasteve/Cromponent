#!/usr/bin/env raku

use lib "lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cromponent;

my UInt $next = 1;

class Start is macro {
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

class Header is macro {
	has UInt $.num where {$_ <= 6} = 1;

	method RENDER {
		Q:to/END/
		<h<.num>>
			<:body>
		</h>
		END
	}
}

my $routes = route {
	add-component Start;
	add-component Head;
	add-component Header;
	get  -> {
		template-with-components Q:to/END/;
		<|Start>
			<|Header-new(:num(2))>Test</|>
		</|>
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
