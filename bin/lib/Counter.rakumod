use WebSocket;
use Cromponent::WebSocket;

class Counter does Cromponent::WebSocket {
	has UInt $.value = 0;

	method LOAD   { $.new }
	method new(|) { $ //= $.bless }

	method RENDER {
		Q:to/END/;
			<button
				id='counter'
				hx-put="./counter/increment"
			>
				<.value>
			</h2>
		END
	}

	method increment is accessible{ :http-method<PUT> } {
		$!value++;
		self.&emit-to-groups;
		Nil
	}
}

sub EXPORT() {
	Counter.^exports
}
