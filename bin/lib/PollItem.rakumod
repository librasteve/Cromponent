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

	method RENDER {
		Q:to/END/;
		<tr>
			<td><label for="poll_<.poll-id>"><.descr></label></td>
			<?.poll.did-user-vote>
				<td>
					<div class="bar-container">
						<div class="bar-fill" style="width: <.percentage>%"></div>
					</div>
				</td>
				<td><.percentage>%</td>
				<td>(<.votes> vote<?{.votes != 1}>s</?>)</td>
			</?>
			<!>
				<td>
					<button
						id="poll_<.poll-id>_item_<.id>"
						hx-put="/poll-item/<.id>/vote"
						hx-vals='js:{ item: <.id> }'
						hx-target="closest .poll"
						hx-swap="outerHTML"
					>vote</button>
				</td>
			</!>
		</tr>
		END
	}

	method percentage(--> Int()) {
		$.votes / $!poll.votes * 100 if $!poll.votes
	}

	method vote(Str :$*user is cookie) is accessible{ :http-method<PUT>, :returns-cromponent } {
		red-do :transaction, {
			$!votes++;
			self.^save;
			$!poll.votes.create: :$*user;
			redraw $!poll;
			$!poll
		}
	}
}

sub EXPORT { PollItem.^exports }
