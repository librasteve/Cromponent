use Cromponent;

unit class Header is macro;

has UInt $.num where {$_ <= 6} = 1;

method RENDER {
	Q:to/END/
	<h<.num>>
		<:body>
	</h>
	END
}
