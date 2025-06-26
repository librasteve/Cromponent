use Cromponent;
use Cromponent::Traits;
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;

class WebSocket does Cromponent is macro {
  has Str $.plugin-url = "https://unpkg.com/htmx.org@1.9.12/dist/ext/ws.js";
  has Str $.url        = "/cromponent-ws";

  WebSocket::<%groups>;
  sub emit-to-groups($component) is export {
    my Str $html = $component.Str;
    my Str @keys = $component.KEYS;
    for @keys -> $key {
      next unless WebSocket::<%groups>{$key}:exists;
      for WebSocket::<%groups>{$key}.values -> $supplier {
        CATCH {
          default {
            next
          }
        }
        $supplier.emit: $html
      }
    }
  }

  method RENDER {
    Q:to/END/;
    <script src="<.plugin-url>"></script>
    <div hx-ext="ws" ws-connect="<.url>">
      <:body>
    </div>
    END
  }

  method EXTRA-ENDPOINTS {
    my $next-id;
    note "adding GET /cromponent-ws";
    get -> "cromponent-ws" {
      my $tag = $.^name;
      web-socket
      :body-parsers(Cro::WebSocket::BodyParser::JSON),
      -> $input, $close {
        my %ids;
        my Supplier $supplier .= new;
        my $id = $next-id++;
        supply {
          my $*CROMPONENT-COMPONENT-REQUEST = True;
          whenever $close {
            for %ids.kv -> $key, $ids {
              WebSocket::<%groups>{$key}{|$ids}:delete;
              WebSocket::<%groups>{$key} if WebSocket::<%groups>{$key}.elems == 0;
            }
          }
          whenever $input {
            my $entry = await .body;
            my @keys = $entry<cromponent-websocket-keys>;
            for @keys -> $key {
              next if %ids{$key}:exists;
              %ids.push: $key => $id;
              WebSocket::<%groups>{$key}{$id} = $supplier;
            }
            whenever $supplier.Supply -> $html {
              emit $html
            }
            LAST {
              for %ids.kv -> $key, $id {
                WebSocket::<%groups>{$key}{|$id}:delete;
                WebSocket::<%groups>{$key}:delete unless WebSocket::<%groups>{$key}.elems;
              }
            }
          }
        }
      }
    }
  }
}

sub EXPORT() {
	BEGIN WebSocket.^exports;
}
