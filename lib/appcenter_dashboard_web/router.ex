defmodule Elementary.AppcenterDashboardWeb.Router do
  use Elementary.AppcenterDashboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Elementary.AppcenterDashboardWeb.LayoutView, "root.html"}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Elementary.AppcenterDashboardWeb do
    pipe_through :browser

    get "/", HomepageController, :index
    get "/submissions", SubmissionController, :index
    get "/submissions/add", SubmissionController, :get
    post "/submissions/add", SubmissionController, :add
    get "/submissions/status", SubmissionController, :get
    post "/submissions/status", SubmissionController, :status

    get "/auth/:provider", AuthController, :index
    get "/auth/:provider/callback", AuthController, :callback
    post "/auth/:provider/callback", AuthController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", Elementary.AppcenterDashboardWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: Elementary.AppcenterDashboardWeb.Telemetry
    end
  end
end
