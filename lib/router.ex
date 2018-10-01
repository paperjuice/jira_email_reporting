defmodule EmailReport.Router do
  @moduledoc false

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/email-report/:story" do
    html_resp = EmailReport.send_request(story)

    send_resp(conn, 200, html_resp)
  end

  match _ do
    send_resp(conn, 404, "That is some garbage I don't understand (╯°□°）╯︵ ┻━┻")
  end
end
