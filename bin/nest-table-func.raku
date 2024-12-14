#!/usr/bin/env raku

use lib "lib";
use Cromponent;
use Cromponent::MyLib;

my $template;
my $topic;

{  #use a block to avoid namespace collision
    use HTML::Functional;

    $template =
        html :lang<en>, [
            head [ script :src<https://unpkg.com/htmx.org@2.0.3"> ],
            body [
                mytable $[[1, 2], [3, 4]], :$topic;
                row $[5,6], :$topic;
                cell 42, :$topic;
            ]
        ];

}

#| Notes:
#| - the $topic hash is loaded with needed Component objects
#| - $topic<mytable> = MyTable.new: $[[1, 2], [3, 4]]; and so on
#| - just use the $topic variable as the 2nd argument to
#|     template-with-components call
#|
#| - itemize list args eg $[5,6] to avoid them being slurped
#| - use semi-colon separator also to avoid slurping all subs


use Cro::WebApp::Template;
use Cro::HTTP::Router;
use Cro::HTTP::Server;

my $routes = route {
    add-components MyTable, Row, Cell;

    get  -> {
        template-with-components $template, $topic;
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

