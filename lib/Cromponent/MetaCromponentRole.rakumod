use Cromponent::CroTemplateOverrides;
unit role Cromponent::MetaCromponentRole;

sub to-kebab(Str() $_) {
	lc S:g/(\w)<?before <[A..Z]>>/$0-/
}

method add-cromponent-routes(
	$component    is copy,
	:&load        is copy,
	:delete(&del) is copy,
	:&add         is copy,
	:&update      is copy,
	:$url-part = $component.^shortname.&to-kebab,
	:$macro    = $component.HOW.?is-macro($component) // False,
) is export {
	my $cmp-name = $component.^name;
	use Cro::HTTP::Router;
	without $*CRO-ROUTE-SET {
		die "Cromponents should be added from inside a `route {}` block"
	}
	my $route-set := $*CRO-ROUTE-SET;

	my @loads = &load.defined
	?? &load.candidates
	!! do with $component.^find_method: "LOAD" {
		.candidates.map: {
			my $sig = .signature.params.skip.head(*-1)>>.gist.join: ", ";
			my $call = .signature.params.skip.head(*-1)>>.name.join: ", ";
			"-> $sig \{ \$component.LOAD{ ": $call" if $call} }".EVAL
		}
	}

	for @loads.sort(-*.count) -> &load {
		&add    //= -> *%pars       { $component.ADD: |%pars               } if $component.^can: "ADD";
		&del    //= -> $id?         { load(|($_ with $id)).DELETE          } if $component.^can: "DELETE";
		&update //= -> $id?, *%pars { load(|($_ with $id)).UPDATE: |%pars  } if $component.^can: "UPDATE";

		my $load-sig  = &load.signature.params.map({
			my Str $type = .type.HOW ~~ Metamodel::CoercionHOW
				?? .type.^constraint_type.^name
				!! .type.^name
			;

			my Str $name = .name;

			"$type $name"
		}).join: ", ";
		my $call-pars = &load.signature.params.map({ .name }).join(", ");
		my $l = qq[-> $load-sig \{
			my \$obj = load $call-pars;
			die "Cromponent '$cmp-name' could not be loaded\{ " with '$call-pars'" if ($call-pars) }" without \$obj;
			\$obj
		}];
		my &LOAD = $l.EVAL;
		my $path = &load.signature.params.map({ "/<{ .type.^name } { .name }>" });

		note "adding GET { $url-part }$path";
		get ("-> '$url-part'{ ", $load-sig" if $load-sig}" ~ q[ {
			my $tag = $component.^name;
			my $comp = LOAD ] ~ $call-pars ~ Q[;
			content 'text/html', $comp.Str
		}]).EVAL;

		with &add {
			post ("-> '$url-part' " ~ q[{
				request-body -> $data {
					my $new = add |$data.pairs.Map;
					if $new.^roles.map(*.^name).first: "Cromponent" {
						content 'text/html', $new.Str
					} elsif &load.count > 0 {
						redirect "$url-part/{ $new.id }", :see-other
					} else {
						redirect "$url-part", :see-other
					}
				}
			}]).EVAL;
		}

		with &del {
			note "adding DELETE $url-part$path";
			my $code = "-> '$url-part', " ~ q[$id {
				del $id;
				content 'text/html', ""
			}];
			my $deleted = delete $code.EVAL;
			if $deleted.^roles.map(*.^name).first: "Cromponent" {
				content $deleted.Str
			}
		}

##### FIXME CROMPONENT MetaCromponentRole.rakumod LINE 97 ####
		with &update {
			note "adding PUT $url-part$path";
			put ("-> '$url-part', " ~ q[$id {
				request-body -> $data {
					my $updated = update $id, |$data.pairs.Map;
					if $updated.^roles.map(*.^name).first: "Cromponent" {
						return content $updated.Str
					}
					if $updated.^roles.map(*.^name).first: "Component" {
						content 'text/html', $updated.HTML
					}
					$updated
				}
			}]).EVAL;
		}

		for $component.^methods.grep(*.?is-accessible) -> $meth {
			my $name = $meth.is-accessible-name;
			my $returns-cromponent = $meth.?returns-cromponent;
			my $returns-html = $meth.?returns-html;

			note "adding {$meth.http-method.uc} $url-part$path/$name";
			if $meth.http-method.uc ne "GET" {
				http $meth.http-method.uc, ("-> '$url-part'{", $load-sig" if $load-sig} " ~ q[, Str $__method-name {
					request-body -> $data {
						my $ret = LOAD(] ~ $call-pars ~ Q[)."$__method-name"(|$data.pairs.Map);
						do if $returns-cromponent {
							content 'text/html', $ret.Str
						} elsif $returns-html {
							content 'text/html', $ret
						} else {
							] ~ qq[redirect "..{ "/{ $call-pars }" if $call-pars }", :see-other
						}
					}
				}]).EVAL;
			} else {
				my @params = $meth.signature.params.skip.head(*-1);
				my $query  = @params.map({", { .gist } is query"}).join: ", ";
				my $params = @params.map({":{.name}"}).join: ", ";

				get ("-> '$url-part'{", $load-sig" if $load-sig}" ~ q[, Str $__method-name] ~ ($query if @params) ~ q[ {
					my $ret = LOAD(] ~ $call-pars ~ Q[)."$__method-name"(] ~ $params ~ q[);
					do if $returns-cromponent {
						content 'text/html', $ret.Str
					} elsif $returns-html {
						content 'text/html', $ret
					} else {
						] ~ qq[redirect "..{ "/{ $call-pars }" if $call-pars }", :see-other
					}
				}]).EVAL;
			}
		}
	}
}

method exports(Mu:U $class) {
	my Str $compiled = $class.&compile-cromponent;
	my $name = $class.^shortname;
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
