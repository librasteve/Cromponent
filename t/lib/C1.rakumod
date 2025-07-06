use Cromponent;

class C1 does Cromponent {
  has $.data = 42;
  method RENDER {
    Q:to/END/;
    component: <.data>
    END
  }
}

sub EXPORT() { C1.^exports }

