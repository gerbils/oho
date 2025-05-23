load "config/shared_routes.rb"

Rails.application.routes.draw do
  # mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app


  resources :wombats
  resources :upload_channels
  resources :royalty_sources
  root "home#index"

  namespace :creators do
    resources :build_statuses do
      member do
        get :pdf
        get :log
        get :hide_log
      end
    end

    resources :author_calendar_items do
      delete 'delete_old', on: :collection
    end

    get "royalties(.:format)",              to: "royalties#index", as: :royalties
    get "royalties/:year/:month(.:format)", to: "royalties#show",  as: :royalty
    # get "creators(.:format)",               to: "creators_home#index",  as: :creators
    root "creators_home#index"

    get "sales(.format)",                   to: "sales#index",     as: :sales
    get "sales/chart/:id/:title",           to: "sales#chart",     as: :sales_chart

  end

  get "/royalties", to: "royalty#index"
  namespace :royalty do
    # get "/uploads", to: "royalty_upload#index"
    resources :uploads, only: [:index, :new, :show, :create, :destroy] do
      put "import", on: :member
    end
    get "/test/:id", to: "uploads#test", as: :test_upload
  end
end
