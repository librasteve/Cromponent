use Red:api<2> <refreshable>;

unit model PollVote;

has UInt $.id      is serial;
has Str  $.user    is column;
has      $.poll-id is referencing( *.id, :model<Poll> );
has      $.poll    is relationship(*.poll-id, :model<Poll>);
