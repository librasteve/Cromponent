use Cromponent;
use Cromponent::Traits;

class Boilerplate does Cromponent is macro {
  has Bool $.htmx         = False;
  has Str  $.lang         = "en";
  has Str  $.title        = "Cromponent Boilerplate";
  has Str  $.base;
  has Str  @.style-sheets;
  has Str  @.scripts;

  method RENDER {
    Q:to/END/;
    <!DOCTYPE html>
    <html lang="<.lang>">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title><.title></title>
        <@.style-sheets>
          <link rel="stylesheet" href="<$_>">
        </@>
        <?.htmx>
          <script
            src="https://unpkg.com/htmx.org@2.0.3"
            integrity="sha384-0895/pl2MU10Hqc6jd4RvrthNlDiE9U1tWmX7WRESftEDRosgxNsQG/Ze9YMRzHq"
            crossorigin="anonymous"
          ></script>
        </?>
        <?.base><base href="<.base>"></?>
      </head>
      <body>
        <:body>
        <@.scripts>
          <script src="<$_>"></script>
        </@>
      </body>
    </html>
    END
  }
}

sub EXPORT() {
	BEGIN Boilerplate.^exports;
}
