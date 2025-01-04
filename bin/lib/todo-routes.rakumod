use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Todo;

sub todo-routes is export {
	route {
		template-location "resources/";

		Todo.^add-cromponent-routes;

		get -> { template "todo-base.crotmp", { :todos(Todo.all), :base</todo/> } }
	}
}
