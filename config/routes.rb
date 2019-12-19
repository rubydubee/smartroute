Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root :to => 'agencies#landing'
  get 'agencies' => 'agencies#index'
  get 'agencies/:link' => 'agencies#show'
  get 'agencies/:id/closest' => 'agencies#closest'
  get 'agencies/:id/departures' => 'agencies#departures'
  get 'favorites' => 'agencies#favorites'
  get 'favorites/route_departures' => 'agencies#route_departures'
end
