use Rack::Static, :urls => ['/stylesheets', '/javascripts'], :root => 'public'
require File.dirname(__FILE__) + '/app'
run CallForwarding::App
