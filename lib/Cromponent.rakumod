my @components-sub;
my @components-macro;

class CromponentHandler does Callable {
	has &.handler;
	has $.method;
	has $.route-set;
	method signature { &!handler.signature }
	method CALL-ME(|c) {
		my $*CRO-ROUTE-SET := $!route-set;
		&!handler.(|c)
	}
}

role WithCromponents {
	has %.cromponents is rw;

	method add-handler($method, &handler) {
		my $route-set := $*CRO-ROUTE-SET;
		callwith $method, CromponentHandler.new: :&handler, :$method, :$route-set;
	}
}

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

multi add-components(*@components) is export {
	for @components -> Mu:U $component {
		add-component $component
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
) is export {
	use Cro::HTTP::Router;
	without $*CRO-ROUTE-SET {
		die "Cromponents should be added from inside a `route {}` block"
	}
	my $route-set := $*CRO-ROUTE-SET;
	$ = $route-set does WithCromponents unless $route-set ~~ WithCromponents;

	my %cromponents := $route-set.cromponents;

	%cromponents.push: $component.^name => %(:&load, :&delete, :$component, :tag-type($macro ?? 'macro' !! 'sub'));

	&load   //= -> $id         { $component.LOAD: $id      } if $component.^can: "LOAD";
	&create //= -> *%pars      { $component.CREATE: |%pars } if $component.^can: "CREATE";
	&del    //= -> $id         { load($id).DELETE          } if $component.^can: "DELETE";
	&update //= -> $id, *%pars { load($id).UPDATE: |%pars  } if $component.^can: "UPDATE";

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
			template-with-components "<\&{ $tag }( .comp )>", { :$comp };
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

sub cromponent-to-tmpl($component, $tag = "sub") {
	my $sig  = $component.^attributes.grep(*.has_accessor).map({ ":\${ .name.substr(2) }" }).join: ", ";
	my $name = $component.^name;
	my $t    = $component.RENDER;
	my $call = $tag eq "sub" ?? "&" !! "|";
	qq:to/END/
	<:{ $tag } {$name}(\$_)>
	$t.indent(4)
	</:{ $tag }>
	END
}

sub template-with-components($template, $data?) is export {
	use Cro::WebApp::Template;
	my $route-set := $*CRO-ROUTE-SET;
	my %cromponents := $route-set.cromponents;

	my $header = %cromponents.values.map({
		my $sig  = .<component>.^attributes.grep(*.has_accessor).map({ ":\${ .name.substr(2) }" }).join: ", ";
		my $name = .<component>.^name;
		my $t    = .<component>.RENDER;
		my $tag  = .<tag-type> // "sub";
		my $call = $tag eq "sub" ?? "&" !! "|";
		qq:to/END/
		<:{ $tag } {$name}(\$_ = \$cromponents.{$name})>
		$t.indent(4)
		</:{ $tag }>
		<:{ $tag } {$name}-new({ $sig })>
			<{ $call }{ $name }(\$cromponents.{ $name }.new({ $sig }))> { " <:body> </{ $call }{ $name }> " if $tag eq "macro" }
		</:{ $tag }>
		END
	}).join: "\n";
	my $wrapped-data = {
		:$data,
		:cromponents(%cromponents.kv.map(-> $key, % (:$component, |){ $key => $component }).Map)
	};
	my $wrapped-template = qq:to/END/;
		<:sub cromponent-wrapper\(\$cromponents, \$_)>
		$header.indent(4)
		$template.indent(4)
		</:sub>
		<&cromponent-wrapper\(.cromponents, .data)>
		END
	#say $wrapped-template;
	#say $wrapped-data;

	template-inline $wrapped-template, $wrapped-data;
}

sub compile-cromponent($cromponent) {
	use Cro::WebApp::Template::Repository;
	use Cro::WebApp::Template::Parser;
	use Cro::WebApp::Template::ASTBuilder;

	my $*TEMPLATE-FILE = $cromponent.^name.IO;
	my $code = $cromponent.&cromponent-to-tmpl: |("macro" if $cromponent.HOW.?is-macro($cromponent));

	my $*TEMPLATE-REPOSITORY = get-template-repository;
	my $ast = Cro::WebApp::Template::Parser.parse(
		$code,
		actions => Cro::WebApp::Template::ASTBuilder
	).ast;
	$ast.compile
}

multi EXPORT(+@add --> Map()) {
	'&trait_mod:<is>' => &trait_mod:<is>,
	'&EXPORT' => sub (--> Map()) {
		|@components-sub.map(-> $cmp {
			|$cmp.&compile-cromponent<exports><sub>.kv.map: -> $name, $sub {
				"&__TEMPLATE_SUB__$name" => sub ($comp = $cmp, |c) {
					with $comp {
						$sub.($_, |c)
					} else {
						$sub.($cmp.new: |c)
					}
				},
			}
		}),
		|@components-macro.map: -> $cmp {
			|$cmp.&compile-cromponent<exports><macro>.kv.map: -> $name, $macro {
				"&__TEMPLATE_MACRO__$name" => sub (&body, $comp = $cmp, |c) {
					with $comp {
						$macro.(&body, $_, |c)
					} else {
						$macro.(&body, $cmp.new: |c)
					}
				}
			}
		},
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
