use Cromponent;

class M1 does Cromponent is macro {
  has $.data = 42;
  method RENDER {
    Q:to/END/;
    component: <.data>; body: <:body>
    END
  }
}

sub EXPORT { M1.^exports }

