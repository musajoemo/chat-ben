Rails.application.routes.draw do
  get 'static_pages/home'

  mount ActionCable.server => "/cable"

  get "/404" => "errors#not_found"
  get "/500" => "errors#internal_server_error"

  resources :feedbacks, only: [:create, :new, :index], path: 'feedback'
  resources :reactions, only: [:create]

  get '/new_chat', to: 'posts#new_chat'
  resources :posts
  resources :bins, path: 'channel'
  resources :bins

  resources :reactions, only: [:index]

  resources :participations, only: :destroy
  resources :rooms, only: [:show, :update], path: 'chat', param: :token
  resources :ratings, only: :create
  devise_for :users#, controllers: { sessions: "users/sessions" }

  root 'static_pages#home'

  get 'banned' => 'ratings#banned'

  get 'emails' => 'bins#emails'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
