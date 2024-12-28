unit role Tag;

has @.classes;
has $.id;

method arguments {
	'<?.classes>class=<@.classes><$_></@></?> <?.id>id=<.id></?>'
}
