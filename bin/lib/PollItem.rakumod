use WebSocket;
use Red:api<2> <refreshable>;
use Cromponent;
use Cro::HTTP::Router;
use PollVote;

model PollItem does Cromponent {
	has UInt $.id      is serial;
	has Str  $.descr   is column;
	has UInt $.poll-id is referencing(*.id, :model<Poll>);
	has      $.poll    is relationship(*.poll-id, :model<Poll>);
	has UInt $.votes   is column is rw = 0;

	method LOAD(Int $id) { $.^load: $id }
	method EXPORT { [$!id, ] }
	method RENDER {
		Q:to/END/;
		<label for="poll_<.poll-id>"><.descr></label>
		<button
			id="poll_<.poll-id>_item_<.id>"
			hx-put="/poll-item/<.id>/vote"
			hx-vals='js:{ item: <.id> }'
			hx-target="closest .poll"
		>
			vote
		</button>
		END
	}

	method percentage(--> Int()) {
		return 0 unless $!poll.total-votes;
		(($.votes / $!poll.total-votes) * 100)
	}

	method vote(Str :$user is cookie) is accessible{ :http-method<PUT>, :returns-cromponent } {
		red-do :transaction, {
			$!votes++;
			self.^save;
			$!poll.votes.create: :$user;
			$!poll
		}
	}
}

sub EXPORT() {
	PollItem.^exports
}
