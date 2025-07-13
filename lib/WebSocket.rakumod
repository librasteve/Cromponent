use v6.d;
use Cromponent;
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;
use Cromponent::MetaCromponentRole;
use JSON::Fast;
use Tuple;

class WebSocket does Cromponent is macro {
  has Str $.plugin-url = "https://unpkg.com/htmx.org@1.9.12/dist/ext/ws.js";
  has Str $.url        = "/cromponent-ws";

  method declare-components {
    @.children.map({ self!declare-component: $_ }).join: '';
  }
  
  method RENDER {
    my @*CROMPONENTS;
    Q:to/END/;
    <script src="<.plugin-url>"></script>
    <div hx-ext="ws" ws-connect="<.url>">
      <:body>
      <&HTML(.declare-components)>
    </div>
    END
  }

  method !declare-component($child) {
    return Empty unless $child.^find_method: "IDS";
    qq:to/END/;
    <div
      ws-send
      hx-trigger="load once"
      hx-vals='\{"cromponent": { to-json [ $child.^name, |$child.IDS ] }}'
    ></div>
    END
  }

  sub note-route-added(Str $method, Str $path) {
    return unless %*ENV<CROMPONENT_ROUTES_ADDED>;
    note "adding $method $path"
  }

  my SetHash %conn{Tuple};

  subset CromponentWithIds of Cromponent where { .^can: "IDS" }

  multi redraw(CromponentWithIds $obj) is export {
    redraw $obj.WHAT, [ |$obj.IDS, ]
  }

  multi redraw(Cromponent:U $class, @ids) is export {
    redraw $class.^name, @ids
  }

  multi redraw(Str $class, @ids) is export {
    my Tuple $tuple .= new: [ $class, |@ids ];
    .emit: $tuple for %conn{ $tuple }.keys
  }

  sub dyn-load(Str $type) {
    state Any:U %cache;
    return %cache{$type} if %cache{$type}:exists;

    require ::($type);
    %cache{$type} = ::($type);
  }

  method EXTRA-ENDPOINTS {
    use Cro::HTTP::Router;
    note-route-added "GET", "cromponent-ws";
    get ->
      "cromponent-ws",
      :%COOKIES is cookie,
      :%QUERIES is query,
      :%HEADERS is header,
      :%AUTHS   is auth,
    {

      my %all-tuples is SetHash;
      my Supplier $supplier .= new;

      web-socket
        :body-parsers(Cro::WebSocket::BodyParser::JSON),
        -> $input, $close {

          my &del-conn = sub {
            for %all-tuples.keys -> $tuple {
              %conn{$tuple}{$supplier}:delete;
            }
          }

          supply {
            whenever $input {
              CATCH {
                default {
                  .say
                }
              }

              my %body = await .body;
              my @cromp = %body<cromponent>[];
              my $tuple = Tuple.new: @cromp;
              %all-tuples{$tuple} = True;
              %conn{$tuple}{$supplier} = True;
              LAST del-conn;
            }

            whenever $close { del-conn }

            whenever $supplier.Supply -> ($type, *@params) {
              my &LOAD = $type.&dyn-load.^find_method: "LOAD";

              my sub get-data(*@params --> Map()) {
                my :(:@scalar, :@hash) := @params.classify: { .sigil eq '%' ?? "hash" !! "scalar" };

                my %scalar := do {
                  my :(:@cookie, :@query, :@header, :@auth, |) := @scalar.classify: { .?trait-used // "" };

                  @cookie .= map: { |.named_names };
                  @query  .= map: { |.named_names };
                  @header .= map: { |.named_names };
                  @auth   .= map: { |.named_names };

                  Map.new: (
                    |(@cookie Z=> %COOKIES{ @cookie } if @cookie),
                    |(@query  Z=> %QUERIES{ @query  } if @query ),
                    |(@header Z=> %HEADERS{ @header } if @header),
                    |(@auth   Z=> %AUTHS{   @auth   } if @auth  ),
                  )
                }

                my %hash := do {
                  my :(:@cookie, :@query, :@header, :@auth, |) := @hash.classify: { .?trait-used // "" };

                  @cookie .= map: { |.named_names };
                  @query  .= map: { |.named_names };
                  @header .= map: { |.named_names };
                  @auth   .= map: { |.named_names };

                  Map.new: (
                    |($_ => %COOKIES for @cookie),
                    |($_ => %QUERIES for @query ),
                    |($_ => %HEADERS for @header),
                    |($_ => %AUTHS   for @auth  ),
                  )
                }

                Map.new: (|%scalar, |%hash);
              }

              my %map := Map.new: get-data &LOAD.signature.params;
              my $obj = LOAD $type.&dyn-load, |@params, |%map;

              with $obj.^find_method: "REDRAW" {
                my %map := Map.new: get-data .signature.params;
                emit $obj.REDRAW: |%map;
              } else {
                emit $obj.Str
              }
            }
          }
        }
      ;
    }
  }
}

sub EXPORT { WebSocket.^exports }
