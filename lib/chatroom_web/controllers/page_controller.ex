defmodule ChatroomWeb.PageController do
  use ChatroomWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
