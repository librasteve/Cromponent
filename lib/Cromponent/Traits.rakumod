unit module Cromponent::Traits;

multi trait_mod:<is>(Mu:U $comp, Bool :$macro!) is export {
	my role CromponentMacroHOW {
		method is-macro(|) { True }
	}
	$comp.HOW does CromponentMacroHOW
}

multi trait_mod:<is>(Method $m, Bool :$accessible!) is export {
	trait_mod:<is>($m, :accessible{})
}

role TraitUsed { has Str $.trait-used }

multi trait_mod:<is>(Parameter:D $param, :$query! --> Nil) is export {
	$param does TraitUsed("query");
}
multi trait_mod:<is>(Parameter:D $param, :$header! --> Nil) is export {
	$param does TraitUsed("header");
}
multi trait_mod:<is>(Parameter:D $param, :$cookie! --> Nil) is export {
	$param does TraitUsed("cookie");
}
multi trait_mod:<is>(Parameter:D $param, :$auth! --> Nil) is export {
	$param does TraitUsed("auth");
}

multi trait_mod:<is>(
	Method $m,
	:%accessible! (
		:$name = $m.name,
		:$returns-cromponent = False,
		:$returns-html = False,
		:$http-method = "GET",
	)
) is export {
	my role IsAccessible {
		has Str  $.is-accessible-name is rw;
		method is-accessible { True }
	}
	
	my role ReturnsCromponent {
		method returns-cromponent { True }
	}

	my role ReturnsHtml {
		method returns-html { True }
	}

	my role HTTPMethod {
		has Str $.http-method;
	}

	$m does IsAccessible($name);
	$m does ReturnsCromponent if $returns-cromponent;
	$m does ReturnsHtml if $returns-html;
	$m does HTTPMethod($http-method);
	$m
}
