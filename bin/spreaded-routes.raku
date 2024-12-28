#!/usr/bin/env raku

use lib "lib";
use lib "bin/lib";
use cromponent-routes;
use macro-routes;
use nest-table-func-routes;
use nest-table-lib-routes;
use nest-table-routes;

use Cro::HTTP::Router;
use Cro::HTTP::Server;

my $routes = route {
include cromponent      => cromponent-routes      ;
include macro           => macro-routes           ;
include nest-table-func => nest-table-func-routes ;
include nest-table-lib  => nest-table-lib-routes  ;
include nest-table      => nest-table-routes      ;
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
