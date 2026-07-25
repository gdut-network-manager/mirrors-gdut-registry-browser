Rails.application.routes.draw do
  root to: "projects#index"

  get :ping, to: ->(env) { [ "200", { "Content-Type" => "text/plain" }, [ "pong" ] ] }

  get "/project/:project_name", to: "repositories#index", as: :project, constraints: { project_name: /[^\/]+/ }
  get "/project/:project_name/repo/*repo/tag/:tag", to: "tags#show", as: :tag, constraints: { project_name: /[^\/]+/, tag: /[^\/]+/ }, format: false
  get "/project/:project_name/repo/*repo/tag/:tag/sbom/:sbom_digest", to: "tags#sbom", as: :tag_sbom, constraints: { project_name: /[^\/]+/, tag: /[^\/]+/ }, format: false
  get "/project/:project_name/repo/*repo", to: "repositories#show", as: :repository, constraints: { project_name: /[^\/]+/ }, format: false
end
