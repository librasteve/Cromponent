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
            head [
                script :src<https://unpkg.com/htmx.org@2.0.3">,
                title 'Simple Grid Example'
            ],
            body [
                grid $(1..6), :$topic;
            ],
        ];

}

#`[
# TODOs
- several instances of a component must share a topic entry
  - make topic more like a match var? -or-
  - specify an implicit id
]

#`[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Grid Example</title>
    <style>
        .grid-container {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr; /* Creates 3 equal columns */
            gap: 10px; /* Adds space between grid items */
            padding: 10px;
            background-color: #f2f2f2;
        }

        .grid-item {
            background-color: #4CAF50;
            color: white;
            border: 1px solid #ddd;
            text-align: center;
            padding: 20px;
            font-size: 16px;
        }
    </style>
</head>
<body>
<div class="grid-container">
    <div class="grid-item">1</div>
    <div class="grid-item">2</div>
    <div class="grid-item">3</div>
    <div class="grid-item">4</div>
    <div class="grid-item">5</div>
    <div class="grid-item">6</div>
</div>
</body>
</html>
]


use Cro::WebApp::Template;
use Cro::HTTP::Router;
use Cro::HTTP::Server;

my $routes = route {
    add-components Grid, Item;

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

