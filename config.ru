require_relative './app'
use Rack::Static, :urls => ['/stylesheets', '/javascripts'], :root => 'public'
run CallForwarding::App
