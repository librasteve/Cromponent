use Red:api<2>;
use Cromponent;
use PollItem;

model PollView does Cromponent {
	has Str  $.user    is required;
	has      $.poll    is required;
	has UInt $.poll-id = $!poll.id;

	method LOAD(Int $poll-id, Str $user) {
		require ::("Poll");
		my $poll = ::("Poll").^load: $poll-id;
		$poll.user = $user;
		$.new: :$poll, :$user
	}

	method polls(Str $user) {
		require ::("Poll");
		do for ::("Poll").^all.map(*.id).Seq.sort -> $poll-id {
			self.LOAD: $poll-id, $user
		}
	}

	method items {
		$.poll.items.Seq.map: {
			.user = $!user;
			$_
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
				<@.items div>
					<&HTML($_)>
				</@>
			</!>
		</div>
		END
	}

	method vote(UInt() :$item) is accessible{ :http-method<PUT> } {
		red-do :transaction, {
			require ::("PollItem");
			::("PollItem").^load($item).vote;
			$!poll.votes.create: :$!user;
		}
	}
}

sub EXPORT() {
	PollView.^exports
}
