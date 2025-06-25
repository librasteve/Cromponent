#!/usr/bin/env raku

use lib "bin/lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use WebSocket;
use Clock;

my $routes = route {
	template-location "resources/";
	WebSocket.^add-cromponent-routes;
	Clock.^add-cromponent-routes;

	Supply.interval(1).act: { emit-to-groups Clock.new }

	get -> {
	    template "clock.crotmp", {}
	}
}
my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => "0.0.0.0",
    port => 2000,
    application => $routes,
);
$http.start;
say "Listening at http://0.0.0.0:2000";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}

