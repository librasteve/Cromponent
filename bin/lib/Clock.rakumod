use Cromponent;

class Clock does Cromponent {
	has DateTime $.date-time .= now;

	method LOAD { ::?CLASS.new }

	method RENDER {
		Q:to/END/;
			<h2
				id='clock'
				ws-send
				hx-trigger="load"
				hx-vals='{"cromponent-websocket-keys":<.KEYS-json>}'
			>
				<.date-time.hh-mm-ss>
			</h2>
		END
	}
}

sub EXPORT() {
	Clock.^exports
}
