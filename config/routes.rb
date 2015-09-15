Spree::Core::Engine.routes.draw do
  get '/payfast_success' => 'payfast_return#success'
  get '/payfast_failure' => 'payfast_return#failure'
  get '/payfast_cancel'  => 'payfast_return#cancel'
end
