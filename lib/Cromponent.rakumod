my @components-sub;
my @components-macro;

multi trait_mod:<is>(Mu:U $component, Bool :$macro!) is export {
	$component.HOW does role IsMacro { method is-macro(|) { True } }
	trait_mod:<is>($component, :cromponent);
}

multi trait_mod:<is>(Mu:U $component, Bool :$cromponent!) is export {
	trait_mod:<is>($component, :cromponent{})
}

multi trait_mod:<is>(Mu:U $component, :%cromponent!) is export {
	if %cromponent<macro> || $component.HOW.?is-macro($component) {
		@components-macro.push: $component
	} else {
		@components-sub.push: $component
	}
	$component.HOW does role IsCromponent {
		method add($cromponent, *%pars) {
			
			my %parameters := %(|%cromponent, |%pars).Map;
			add-component $cromponent, |%parameters;
		}
	}
}

sub add-component(
	$component    is copy,
	:&load        is copy,
	:delete(&del) is copy,
	:&create      is copy,
	:&update      is copy,
	:$url-part = $component.^name.lc,
	:$macro    = $component.HOW.?is-macro($component) // False,
) {
	use Cro::HTTP::Router;
	without $*CRO-ROUTE-SET {
		die "Cromponents should be added from inside a `route {}` block"
	}

	&load   //= -> $id         { $component.LOAD: $id      } if $component.^can: "LOAD";
	&create //= -> *%pars      { $component.CREATE: |%pars } if $component.^can: "CREATE";
	&del    //= -> $id         { load($id).DELETE          } if $component.^can: "DELETE";
	&update //= -> $id, *%pars { load($id).UPDATE: |%pars  } if $component.^can: "UPDATE";
	my &compiled = $component.&compile-call-cromponent;

	with &load {
		post -> Str $ where $url-part {
			request-body -> $data {
				my $new = create |$data.pairs.Map;
				redirect "$url-part/{ $new.id }", :see-other
			}
		} with &create;

		get -> Str $ where $url-part, $id {
			my $tag = $component.^name;
			my $comp = load $id;
			my %*WARNINGS;
			my $result = compiled($comp);
			if %*WARNINGS {
				for %*WARNINGS.kv -> $text, $number {
					warn "$text ($number time{ $number == 1 ?? '' !! 's' })";
				}
			}
			content "text/html", $result;
		}

		delete -> Str $ where $url-part, $id {
			del $id;
			content 'text/html', ""
		} with &del;

		put -> Str $ where $url-part, $id {
			request-body -> $data {
				update $id, |$data.pairs.Map
			}
		} with &update;

		for $component.^methods -> $meth {
			my $name = $meth.name;

			if $meth.signature.params > 2 {
				put -> Str $ where $url-part, $id, Str $name {
					request-body -> $data {
						load($id)."$name"(|$data.pairs.Map);
						redirect "../{ $id }", :see-other
					}
				}
			} else {
				get -> Str $ where $url-part, $id, Str $name {
					load($id)."$name"();
					redirect "../{ $id }", :see-other
				}
			}
		}
	}
}

sub cromponent-to-tmpl($component, $tag = $component.HOW.?is-macro($component) ?? "macro" !! "sub") {
	my $name = $component.^name;
	my $t    = $component.RENDER;
	qq:to/END/
	<:{ $tag } {$name}(\$_)>
	$t.indent(4)
	</:{ $tag }>
	END
}

sub call-cromponent-to-tmpl($component, $tag = $component.HOW.?is-macro($component) ?? "macro" !! "sub") {
	my $name = $component.^name;
	my $t    = $component.RENDER;
	my $call = $tag eq "sub" ?? "&" !! "|";
	qq:to/END/
	{cromponent-to-tmpl($component)}
	<{ $call }{$name}(\$_)>{ "</{ $call }>" if $tag eq "macro" }
	END
}

sub compile-cromponent($cromponent) {
	use Cro::WebApp::Template::Repository;
	use Cro::WebApp::Template::Parser;
	use Cro::WebApp::Template::ASTBuilder;

	my $*TEMPLATE-FILE = $cromponent.^name.IO;
	my $code = $cromponent.&cromponent-to-tmpl;

	my $*TEMPLATE-REPOSITORY = get-template-repository;
	my $ast = Cro::WebApp::Template::Parser.parse(
		$code,
		actions => Cro::WebApp::Template::ASTBuilder
	).ast;
	$ast.compile
}

sub compile-call-cromponent($cromponent) {
	use Cro::WebApp::Template::Repository;
	use Cro::WebApp::Template::Parser;
	use Cro::WebApp::Template::ASTBuilder;

	my $*TEMPLATE-FILE = "CALL-{ $cromponent.^name }".IO;
	my $code = $cromponent.&call-cromponent-to-tmpl;

	my $*TEMPLATE-REPOSITORY = get-template-repository;
	my $ast = Cro::WebApp::Template::Parser.parse(
		$code,
		actions => Cro::WebApp::Template::ASTBuilder
	).ast;
	$ast.compile<renderer>
}
sub cromponent-library($component) is export {
	$component.HOW does role IsCromponent {
		method add($cromponent, *%pars) {
			add-component $cromponent, |%pars;
		}
	}
	
	my %comp-exports = $component.&compile-cromponent<exports>;

	return Map.new: (
		|%comp-exports<sub>.kv.map(-> $name, $sub {
			"&__TEMPLATE_SUB__$name" => sub ($comp = $component, |c) {
				my %*WARNINGS;
				my \ret = do with $comp {
					$sub.($_, |c)
				} elsif c {
					$sub.($component.new: |c)
				} else {
					$sub.($component.new)
				}
				if %*WARNINGS {
					for %*WARNINGS.kv -> $text, $number {
						warn "$text ($number time{ $number == 1 ?? '' !! 's' })";
					}
				}
				ret
			},
		}),
		|%comp-exports<macro>.kv.map(-> $name, $macro {
			"&__TEMPLATE_MACRO__$name" => sub (&body, $comp = $component, |c) {
				my %*WARNINGS;
				my \ret = do with $comp {
					$macro.(&body, $_, |c)
				} elsif c {
					$macro.(&body, $component.new: |c)
				} else {
					$macro.(&body, $component.new)
				}
				if %*WARNINGS {
					for %*WARNINGS.kv -> $text, $number {
						warn "$text ($number time{ $number == 1 ?? '' !! 's' })";
					}
				}
				ret
			}
		}),
	)
}


multi EXPORT(--> Map()) {
	'&trait_mod:<is>' => &trait_mod:<is>,
	'&EXPORT' => sub {
		[|@components-sub, |@components-macro].flatmap({ |cromponent-library $_ }).Map
	},
}


=begin pod

=head1 NAME

Cromponent - A way create web components with cro templates

=head1 SYNOPSIS

=begin code :lang<raku>

use Cromponent;
class AComponent {
	has $.data;

	method RENDER {
		Q:to/END/
		<h1><.data></h1>
		END
	}
}

# for how to use that, please follow the examples on the bin/ dir

=end code

=head1 DESCRIPTION

Cromponent is a way create web components with cro templates

=head1 AUTHOR

Fernando Corrêa de Oliveira <fco@cpan.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
