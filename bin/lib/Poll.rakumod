use Red:api<2>;
use Cromponent;

model Poll does Cromponent {
	has UInt $.id    is serial;
	has Str  $.descr is column;
	has      @.items is relationship(*.poll-id, :model<PollItem>);
	has      @.votes is relationship(*.poll-id, :model<PollVote>);

	method LOAD(Int $poll-id) {
		Poll.^load: $poll-id
	}

	method sorted-items {
		@!items.sort: {
			|(-.votes if $.did-user-vote),
			.id
		}
	}

	method RENDER {
		Q:to/END/;
		<div class="poll">
			<h2>
				<a href="/polls/<.id>">
					<.descr> (<.votes.elems> vote<?{ .votes.elems != 1 }>s</?>)
				</a>
			</h2>
			<table>
				<@.sorted-items.Seq>
					<&HTML($_)>
				</@>
			</table>
		</div>
		END
	}

	method did-user-vote($user = $*user) {
		?@.votes.first: *.user eq $user
	}
}

sub EXPORT() { Poll.^exports }
