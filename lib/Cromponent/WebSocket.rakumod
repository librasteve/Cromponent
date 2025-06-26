use Cromponent;
use JSON::Fast;

sub EXPORT(--> Map()) {
	use Cromponent::Traits;
	Cromponent::Traits::EXPORT::ALL::
}

unit role Cromponent::WebSocket does Cromponent;

method KEYS {
	[ $.^name, ]
}

method KEYS-json {
	to-json $.KEYS
}

method declare-ws-component {
	qq:to/END/;
	<div
		ws-send
		hx-trigger="load once"
		hx-vals='\{"cromponent-websocket-keys": { $.KEYS-json }}'
	></div>
	END
}

method custom-transformation($html) {
	join "\n", $html, $.declare-ws-component
}
