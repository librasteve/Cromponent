#!/usr/bin/env raku

use lib "bin/lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;
use Poll;
use PollView;
use PollItem;
use PollVote;
use Red:api<2>;

my $routes = route {
	PROCESS::<$RED-DEBUG> = %*ENV<RED_DEBUG>;
	red-defaults "SQLite";
	Poll.^create-table:     :unless-exists;
	PollItem.^create-table: :unless-exists;
	PollVote.^create-table: :unless-exists;

	template-location "resources/";
	# Poll.^add-cromponent-routes;
	PollView.^add-cromponent-routes;

	Poll.^create:
	    :descr('test01'),
	    :items[
		%(:descr('item01.01')),
		%(:descr('item01.02')),
	    ]
	;

	Poll.^create:
	    :descr('test02'),
	    :items[
		%(:descr('item02.01')),
		%(:descr('item02.02')),
	    ]
	;

	get -> Str $user, 'polls' {
		template "polls.crotmp", {
			user  => $user,
			polls => PollView.polls: $user
		}
	}

	get -> Str $user, 'polls', UInt $id {
		my $poll-view = PollView.LOAD: $id, $user;
		template "polls.crotmp", {
			user  => $user,
			polls => [$poll-view,]
		}
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

