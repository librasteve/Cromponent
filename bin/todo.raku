#!/usr/bin/env raku

use lib "lib";
use lib "bin/lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Cromponent;
use Todo;

my $routes = route {
	#resources-from %?RESOURCES;
	#templates-from-resources;
	template-location "resources/";

	Todo.^add;

	get -> { template "todo-base.crotmp", { :todos(Todo.all) } }
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

