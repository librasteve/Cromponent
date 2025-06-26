multi trait_mod:<is>(Mu:U $comp, Bool :$macro!) is export {
	my role CromponentMacroHOW {
		method is-macro(|) { True }
	}
	$comp.HOW does CromponentMacroHOW
}

multi trait_mod:<is>(Method $m, Bool :$accessible!) is export {
	trait_mod:<is>($m, :accessible{})
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


