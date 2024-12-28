unit class Cromponent;
use Cro::WebApp::Template;
use Cro::HTTP::Router;

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
#my %components;
role WithCromponents {
	has %.cromponents is rw;

	method add-handler($method, &handler) {
		my $route-set := $*CRO-ROUTE-SET;
		callwith $method, CromponentHandler.new: :&handler, :$method, :$route-set;
	}
}

multi add-components(*@components) is export {
	for @components -> Mu:U $component {
		add-component $component
	}
}

sub add-component(
	$component is copy,
	:&load is copy,
	:delete(&del) is copy,
	:&create is copy,
	:&update is copy,
	:$url-part = $component.^name.lc,
	:$macro = False,
) is export {
	my $route-set := $*CRO-ROUTE-SET;
	$ = $route-set does WithCromponents unless $route-set ~~ WithCromponents;

	my %cromponents := $route-set.cromponents;

	%cromponents.push: $component.^name => %(:&load, :&delete, :$component, :tag-type($macro ?? 'macro' !! 'sub'));

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
				my $comp = load $id;
				update $comp, |$data.pairs.Map
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

sub template-with-components($template, $data?) is export {
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
