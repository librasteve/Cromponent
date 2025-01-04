use Cromponent;
use StyledComponent;

class YellowBox does Cromponent does StyledComponent {
	has UInt $.value;

	method CSS {
		q:to/END/
		background-color: yellow;
		color: black;
		width: 100px;
		height: 100px;
		display: flex;
		justify-content: center;
		align-items: center;
		border: 2px solid black;
		border-radius: 10px;
		font-size: 24px;
		font-weight: bold;
		.internal {
			color: red;
		}
		END
	}

	method RENDER {
		q:to/END/
		<div class=<.class>><.value>
			<div class="internal">13</div>
		</div>
		END
	}
}
