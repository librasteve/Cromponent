#!/usr/bin/env raku

use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Todo;

sub todo-routes is export {
	route {
		#resources-from %?RESOURCES;
		#templates-from-resources;
		template-location "resources/";

		Todo.^add;

		get -> { template "todo-base.crotmp", { :todos(Todo.all) } }
	}
}
