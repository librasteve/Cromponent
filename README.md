[![Actions Status](https://github.com/FCO/Cromponent/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Cromponent/actions)

NAME
====

Cromponent - A way create web components with cro templates

SYNOPSIS
========

```raku
use Cromponent;
class AComponent {
	has $.data;

	method RENDER {
		Q:to//END
		<h1><.data></h1>
		END
	}
}

# for how to use that, please follow the examples on the bin/ dir
```

DESCRIPTION
===========

Cromponent is a way create web components with cro templates

AUTHOR
======

Fernando Corrêa de Oliveira <fco@cpan.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

