use Cromponent;
use Cromponent::Traits;
use StyledComponent;

class StyledDiv does Cromponent is macro does StyledComponent {
  multi method new(Str $CSS, *%pars) { self.new: :$CSS, |%pars }
  method RENDER {
    Q:to/END/;
    <div class="<.class>"><:body></div>
    END
  }
}

sub EXPORT() { StyledDiv.^exports }

