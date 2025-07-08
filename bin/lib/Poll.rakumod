use Red:api<2>;
use Cromponent;

model Poll does Cromponent {
	has UInt $.id    is serial;
	has Str  $.descr is column;
	has      @.items is relationship(*.poll-id, :model<PollItem>);
	has      @.votes is relationship(*.poll-id, :model<PollVote>);

	method LOAD(UInt $id) { $.^load: $id }
	method EXPORT   { [ $!id, ] }

	method RENDER {
		Q:to/END/;
		<h2>
			<a href="/polls/<.id>">
				<.descr> (<.total-votes> votes)
			</a>
		</h2>
		<@.items.Seq div>
			<label for="poll_item_<.id>"><.descr></label>
			<progress
				id="poll_item_<.id>"
				max="100"
				value="<.percentage>"
			>
				<.percentage>%
			</progress>
			<.percentage>%
		</@>
		END
	}

	method has-user-voted(Str $user) {
		?@.votes.first: *.user eq $user
	}

	method total-votes {
		@!votes.elems
	}
}

sub EXPORT() {
	Poll.^exports
}
