Spree::Core::Engine.routes.draw do
  post '/payfast_success' => 'payfast_return#success'
  post '/payfast_failure' => 'payfast_return#failure'
  post '/payfast_cancel'  => 'payfast_return#cancel'
end
