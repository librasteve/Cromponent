use Cromponent;
use MyLib;

my $template;
my $topic;

{  #use a block to avoid namespace collision
    use HTML::Functional;

    $template =
        html :lang<en>, [
            head [ script :src<https://unpkg.com/htmx.org@2.0.3"> ],
            body [
                mytable $[[1, 2], [3, 4]], :$topic;
                row $[5,6], :$topic;
                cell 42, :$topic;
            ]
        ];

}


use Cro::HTTP::Router;

sub nest-table-func-routes is export {
    route {
        add-components MyTable, Row, Cell;

        get  -> {
            template-with-components $template, $topic;
        }
    }
}
