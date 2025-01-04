use Cromponent;
use UUID::V4;

use CSS::Writer;
use CSS::Grammar::CSS3;
use CSS::Grammar::AST;

sub parse-stylesheet($css) {
    use CSS::Grammar::CSS3;
    use CSS::Grammar::Actions;
    my CSS::Grammar::Actions $actions .= new;

    CSS::Grammar::CSS3.parse($css, :$actions)
       or die "unable to parse: $css";

    return $/.ast
}

my @styles; 
role StyledComponent {

  has Str $.CSS;
  has Str $.styled-class = self.generate-class;

  method class {
    $.classes.join: " "
  }

  method generate-class { "{ self.^name }-{ uuid-v4 }" }

  with ::?CLASS.^find_method: "classes" {
    .wrap: method { [ |callsame, $!styled-class ] }
  } else {
    ::?CLASS.^add_method: "classes", my method { [ $!styled-class, ] }
  }

  my &store-css = my method {
    note "adding: $!CSS";
    @styles.push: parse-stylesheet ".{ $.classes } \{ { .Str } \}" with $.CSS;
  }

  with ::?CLASS.^find_method: "TWEAK" {
    .wrap: my method (|c) { callsame; store-css self }
  } else {
    ::?CLASS.^add_method: "TWEAK", &store-css
  }

  method stylesheet {
    my CSS::Writer $writer .= new: :!pretty;
    $writer.write: @styles;
  }

  method add-stylesheet-route(:$name = "css") {
    use Cro::HTTP::Router;
    get -> Str $ where { $_ eq $name } {
      content "text/css", $.stylesheet
    }
  }
}

