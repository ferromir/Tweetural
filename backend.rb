require 'sinatra'

get '/' do
	{
		"id" => 1,
		"tweets" => [],
		"summary" => {}
	}.to_s
end