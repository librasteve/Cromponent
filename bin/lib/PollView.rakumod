use Red:api<2>;
use Cromponent;
use PollItem;
use Poll;

model PollView does Cromponent {
	has Str  $.user    is required;
	has      $.poll    is required;
	has UInt $.poll-id = $!poll.id;

	method LOAD(Int $poll-id, Str $user) {
		my $poll = Poll.^load: $poll-id;
		$.new: :$poll, :$user
	}

	method polls(Str $user) {
		do for Poll.^all.map(*.id).Seq.sort -> $poll-id {
			self.LOAD: $poll-id, $user
		}
	}

	method RENDER {
		Q:to/END/;
		<div class="poll">
			<?.poll.has-user-voted(.user)>
				<&HTML(.poll)>
			</?>
			<!>
				<h2>
					<a href="/polls/<.poll-id>">
						<.poll.descr> (<.poll.total-votes> votes)
					</a>
				</h2>
				<@.poll.items.Seq div>
					<&HTML($_)>
				</@>
			</!>
		</div>
		END
	}
}

sub EXPORT() {
	PollView.^exports
}
