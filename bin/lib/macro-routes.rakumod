#!/usr/bin/env raku

use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Cromponent;

sub macro-routes is export {
	route {
		template-location "resources/";
		get  -> { template "macro.crotmp" }
	}
}
