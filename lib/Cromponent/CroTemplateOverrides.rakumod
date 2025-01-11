unit package Cromponent::CroTemplateOverrides;
use Cro::WebApp::Template::Builtins;

my constant %escapes = %(
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
);

multi escape-text(Mu:U $t, Mu $file, Mu $line) {
    %*WARNINGS{"An expression at $file:$line evaluated to $t.^name()"}++;
    ''
}

multi escape-text(Mu:D $text, Mu $, Mu $) {
    $text.Str.subst(/<[<>&]>/, { %escapes{.Str} }, :g)
}

multi escape-attribute(Mu:U $t, Mu $file, Mu $line) {
    %*WARNINGS{"An expression at $file:$line evaluted to $t.^name()"}++;
    ''
}

multi escape-attribute(Mu:D $attr, Mu $, Mu $) {
    $attr.Str.subst(/<[&"']>/, { %escapes{.Str} }, :g)
}

my %pcache;

sub parse(Mu:U $cromponent) {
	my $name = $cromponent.^name;
	.return with %pcache{$name};
	use Cro::WebApp::Template::Repository;
	use Cro::WebApp::Template::Parser;
	use Cro::WebApp::Template::ASTBuilder;

	my $code = $cromponent.RENDER;

	my $*TEMPLATE-FILE = $cromponent.^name.IO;
	my $*TEMPLATE-REPOSITORY = get-template-repository;

	my $*COMPILING-PRELUDE = True;
	my %*WARNINGS;
	my $ast := Cro::WebApp::Template::Parser.parse(
		$code,
		actions => Cro::WebApp::Template::ASTBuilder,
	).ast;
	if %*WARNINGS {
		for %*WARNINGS.kv -> $text, $number {
			warn "$text ($number time{ $number == 1 ?? '' !! 's' })";
		}
	}
	%pcache{$name} = $ast;
	$ast
}

my %cache;
sub comp($code, $name) is export {
	sub {
		%cache{$name} //= $code.EVAL;
	}
}

sub compile($ast, Bool :$macro = False --> Str) is export {
	my $*IN-SUB = False;
	my $*IN-FRAGMENT = False;
	my $children-compiled = $ast.children.map(*.compile).join(", ");
	$macro
		?? 'sub (&__MACRO_BODY__, $_) { join "", (' ~ $children-compiled ~ ') }'
		!! 'sub ($_) { join "", (' ~ $children-compiled ~ ') }'
	;
}
my %scache;
sub compile-cromponent(Mu:U $cromponent) is export {
	my $name = $cromponent.^name;
	.return with %scache{$name};
	my $ast := $cromponent.&parse;
	my Str $code = $ast.&compile: |(:macro if $cromponent.HOW.?is-macro: $cromponent);
	%scache{$name} = $code;
	$code
}

