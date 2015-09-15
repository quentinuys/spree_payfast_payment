Spree::Core::Engine.routes.draw do
  get '/payfast_success' => 'payfast_return#success'
  post '/payfast_notice' => 'payfast_return#notice'
  get '/payfast_cancel'  => 'payfast_return#cancel'
end
