use Cromponent::WebSocket;

class Clock does Cromponent::WebSocket {
	has DateTime $.date-time handles <hh-mm-ss> .= now;

	method LOAD { ::?CLASS.new }

	method RENDER {
		Q:to/END/;
			<h2 id='clock'>
				<.hh-mm-ss>
			</h2>
		END
	}
}

sub EXPORT() {
	Clock.^exports
}
