defmodule EmailReport.Router do
  @moduledoc false

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    file = File.read!("frontend/index.html")

    send_resp(conn, 200, file)
  end

  get "/email-report/:story" do
    {_key, auth_key} =
      Enum.find(conn.req_headers, fn {key, _value} ->
        key == "basic"
      end)
      |> IO.inspect(label: AUTH_KEY)

    html_resp = EmailReport.send_request(auth_key, story)

    conn
    |> send_resp(200, html_resp)
  end

  match _ do
    send_resp(conn, 404, "That is some garbage I don't understand (╯°□°）╯︵ ┻━┻")
  end
end
