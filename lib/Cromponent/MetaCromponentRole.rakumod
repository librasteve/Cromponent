use Cromponent::CroTemplateOverrides;
unit role Cromponent::MetaCromponentRole;

sub to-kebab(Str() $_) { lc S:g/(\w)<?before <[A..Z]>>/$0-/ }

method add-cromponent-routes(
	$component    is copy,
	:&load        is copy,
	:delete(&del) is copy,
	:&create      is copy,
	:&update      is copy,
	:$url-part = $component.^name.&to-kebab,
	:$macro    = $component.HOW.?is-macro($component) // False,
) is export {
	my $cmp-name = $component.^name;
	use Cro::HTTP::Router;
	without $*CRO-ROUTE-SET {
		die "Cromponents should be added from inside a `route {}` block"
	}
	my $route-set := $*CRO-ROUTE-SET;

	&load //= do with $component.^find_method: "LOAD" {
		do if .count > 1 {
			-> $id { $component.LOAD: $id };
		} else {
			-> { $component.LOAD };
		}
	}
	&create //= -> *%pars      { $component.CREATE: |%pars } if $component.^can: "CREATE";
	&del    //= -> $id         { load($id).DELETE          } if $component.^can: "DELETE";
	&update //= -> $id, *%pars { load($id).UPDATE: |%pars  } if $component.^can: "UPDATE";

	with &load {
		my &LOAD = -> $id? {
			my $obj = load |($_ with $id);
			die "Cromponent '$cmp-name' could not be loaded{" with id '$_'" with $id}" without $obj;
			$obj
		}
		with &create {
			note "adding POST $url-part";
			post ("-> '$url-part' " ~ q[{
				request-body -> $data {
					my $new = create |$data.pairs.Map;
					if &load.count > 0 {
						redirect "$url-part/{ $new.id }", :see-other
					} else {
						redirect "$url-part", :see-other
					}
				}
			}]).EVAL;
		}

		if &load.count > 0 {
			note "adding GET $url-part/<id>";
			get ("-> '$url-part', " ~ q[$id {
				my $tag = $component.^name;
				my $comp = LOAD $id;
				content 'text/html', $comp.Str
			}]).EVAL;

			with &del {
				note "adding DELETE $url-part/<id>";
				delete ("-> '$url-part', " ~ q[$id {
					del $id;
					content 'text/html', ""
				}]).EVAL;
			}

			with &update {
				note "adding PUT $url-part/<id>";
				put ("-> '$url-part', " ~ q[$id {
					request-body -> $data {
						update $id, |$data.pairs.Map
					}
				}]).EVAL;
			}

			for $component.^methods.grep(*.?is-accessible) -> $meth {
				my $name = $meth.is-accessible-name;

				if $meth.signature.params > 2 {
					note "adding PUT $url-part/<id>/$name";
					put ("-> '$url-part', " ~ q[$id, Str $name {
						request-body -> $data {
							LOAD($id)."$name"(|$data.pairs.Map);
							redirect "../{ $id }", :see-other
						}
					}]).EVAL;
				} else {
					note "adding GET $url-part/<id>/$name";
					get ("-> '$url-part', " ~ q[$id, Str $name {
						LOAD($id)."$name"();
						redirect "../{ $id }", :see-other
					}]).EVAL;
				}
			}
		} else {
			note "adding GET $url-part";
			get ("-> '$url-part' " ~ q[{
				my $tag = $component.^name;
				my $comp = LOAD;
				content 'text/html', $comp.Str
			}]).EVAL;

			for $component.^methods.grep(*.?is-accessible) -> $meth {
				my $name = $meth.is-accessible-name;

				if $meth.count > 2 {
					note "adding PUT $url-part/$name";
					put ("-> '$url-part', " ~ q[Str $name {
						request-body -> $data {
							LOAD."$name"(|$data.pairs.Map);
							redirect "..", :see-other
						}
					}]).EVAL;
				} else {
					note "adding GET $url-part/$name";
					get ("-> '$url-part', " ~ q[Str $name {
						LOAD."$name"();
						redirect "..", :see-other
					}]).EVAL;
				}
			}
		}
	}
}

method exports(Mu:U $class) {
	my Str $compiled = $class.&compile-cromponent;
	my $name = $class.^name;
	my &compiled = comp $compiled, $name;
	do if $class.HOW.?is-macro: $class {
		Map.new: (
			'&__TEMPLATE_MACRO__' ~ $name => sub (&body, |c) {
				compiled.(&body, $class.new: |c)
			}
		)
	} else {
		Map.new: (
			'&__TEMPLATE_SUB__' ~ $name => sub (|c) {
				compiled.($class.new(|c))
			}
		)
	}
}
