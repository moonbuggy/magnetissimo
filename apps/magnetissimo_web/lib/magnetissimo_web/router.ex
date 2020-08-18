defmodule MagnetissimoWeb.Router do
  use MagnetissimoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MagnetissimoWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  forward "/healthcheck", HealthCheckup, resp_body: "Up!"

  # Other scopes may use custom stacks.
  # scope "/api", MagnetissimoWeb do
  #   pipe_through :api
  # end
end
