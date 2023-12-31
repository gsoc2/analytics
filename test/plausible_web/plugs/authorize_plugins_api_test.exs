defmodule PlausibleWeb.Plugs.AuthorizePluginsAPITest do
  use PlausibleWeb.ConnCase, async: true

  alias Plausible.Plugins.API.Tokens
  alias PlausibleWeb.Plugs.AuthorizePluginsAPI

  import Plug.Conn

  test "plug passes when a token is found" do
    %{id: site_id} = site = insert(:site, domain: "pass.example.com")
    {:ok, _, raw} = Tokens.create(site, "Some token")

    credentials = "Basic " <> Base.encode64("#{site.domain}:#{raw}")

    conn =
      build_conn()
      |> put_req_header("authorization", credentials)
      |> AuthorizePluginsAPI.call()

    refute conn.halted
    assert %Plausible.Site{id: ^site_id} = conn.assigns.authorized_site
  end

  test "plug halts when a token is not found" do
    site = insert(:site, domain: "pass.example.com")

    credentials = "Basic " <> Base.encode64("#{site.domain}:invalid-token")

    conn =
      build_conn()
      |> put_req_header("authorization", credentials)
      |> AuthorizePluginsAPI.call()

    assert conn.halted

    assert json_response(conn, 401) == %{
             "errors" => [
               %{"detail" => "Plugins API: unauthorized"}
             ]
           }
  end

  test "plug halts when no authorization header is passed" do
    conn =
      build_conn()
      |> AuthorizePluginsAPI.call()

    assert conn.halted

    assert json_response(conn, 401) == %{
             "errors" => [
               %{"detail" => "Plugins API: unauthorized"}
             ]
           }
  end
end
