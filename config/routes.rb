Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "notes#index"

  resources :projects do
    resources :notes, only: [ :new, :create ]
  end

  resources :notes do
    collection do
      patch :reorder_pinned
    end
    member do
      patch :toggle_pin
      post :attach_files
      delete "attachments/:attachment_id", to: "notes#purge_attachment", as: :attachment
    end
  end

  namespace :api do
    namespace :v1 do
      get "openapi", to: "openapi#show", as: :openapi
      get "stats", to: "stats#show"
      post "markdown/render", to: "markdown#render_text"

      resources :projects, except: %i[new edit]

      resources :notes, except: %i[new edit] do
        collection do
          patch :reorder_pinned
        end
        member do
          patch :toggle_pin
          get :attachments, to: "note_attachments#index"
          post :attachments, to: "note_attachments#create"
          delete "attachments/:attachment_id", to: "note_attachments#destroy"
        end
      end
    end
  end
end
