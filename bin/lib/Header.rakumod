use Cromponent;
use Cromponent::Traits;

class Header does Cromponent is macro {
	has UInt $.num where {$_ <= 6} = 1;

	method RENDER {
		Q:to/END/
		<h<.num>><:body></h>
		END
	}
}

sub EXPORT() { Header.^exports }
