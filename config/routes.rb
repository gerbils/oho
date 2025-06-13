
Rails.application.routes.draw do
  # mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app
  mount MissionControl::Jobs::Engine, at: "/johnson"

  resources :passwords, param: :token
  resource :session

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

    get  'impersonate/index'
    get  "impersonate(/:search)" => "impersonate#index",  as: :impersonate
    post "impersonate/:id"       => "impersonate#become", as: :become
  end

  namespace :royalties do
    root  "home#index"
    namespace :ips do
      resources :statements, only: [ :index, :show, :update, :destroy ] do
        get "xxx", on: :member, to: "statements#xxx", as: :xxx
        post "upload", on: :collection, to: "statements#create", as: :upload
        put  "import", on: :member
        post "upload_revenue_lines", on: :member, to: "statements#upload_revenue_lines", as: :upload_revenue_lines
        get  "detail/:revenue_line_id", on: :member, to: "statements#detail", as: :detail
      end
    end
    namespace :lp do
      resources :statements, only: [:index, :new, :show, :create, :destroy] do
        put "import", on: :member
      end
    end
  end
end
