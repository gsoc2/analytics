defmodule PlausibleWeb.Plugins.API.Controllers.SharedLinks do
  use PlausibleWeb, :plugins_api_controller

  operation(:index,
    summary: "Retrieve Shared Links",
    parameters: [
      limit: [in: :query, type: :integer, description: "Maximum entries per page", example: 10],
      after: [
        in: :query,
        type: :string,
        description: "Cursor value to seek after - generated internally"
      ],
      before: [
        in: :query,
        type: :string,
        description: "Cursor value to seek before - generated internally"
      ]
    ],
    responses: %{
      ok: {"Shared Links response", "application/json", Schemas.SharedLink.ListResponse},
      unauthorized: {"Unauthorized", "application/json", Schemas.Unauthorized}
    }
  )

  @spec index(Plug.Conn.t(), %{}) :: Plug.Conn.t()
  def index(conn, _params) do
    {:ok, pagination} =
      Context.SharedLinks.get_shared_links(conn.assigns.authorized_site, conn.query_params)

    conn
    |> put_view(Views.SharedLink)
    |> render("index.json", %{pagination: pagination})
  end

  operation(:create,
    summary: "Create Shared Link",
    request_body: {"Shared Link params", "application/json", Schemas.SharedLink.CreateRequest},
    responses: %{
      created: {"Shared Link", "application/json", Schemas.SharedLink},
      unauthorized: {"Unauthorized", "application/json", Schemas.Unauthorized}
    }
  )

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(
        %{body_params: %Schemas.SharedLink.CreateRequest{name: name, password: password}} = conn,
        _params
      ) do
    site = conn.assigns.authorized_site

    {:ok, shared_link} = Context.SharedLinks.get_or_create(site, name, password)

    conn
    |> put_view(Views.SharedLink)
    |> put_status(:created)
    |> put_resp_header("location", shared_links_url(base_uri(), :get, shared_link.id))
    |> render("shared_link.json", shared_link: shared_link, authorized_site: site)
  end

  operation(:get,
    summary: "Retrieve Shared Link by ID",
    parameters: [
      id: [
        in: :path,
        type: :integer,
        description: "Shared Link ID",
        example: 123,
        required: true
      ]
    ],
    responses: %{
      created: {"Shared Link", "application/json", Schemas.SharedLink},
      not_found: {"NotFound", "application/json", Schemas.NotFound},
      unauthorized: {"Unauthorized", "application/json", Schemas.Unauthorized}
    }
  )

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{id: id}) do
    site = conn.assigns.authorized_site

    case Context.SharedLinks.get(site, id) do
      nil ->
        conn
        |> put_view(Views.Error)
        |> put_status(:not_found)
        |> render("404.json")

      shared_link ->
        conn
        |> put_view(Views.SharedLink)
        |> put_status(:ok)
        |> render("shared_link.json", shared_link: shared_link, authorized_site: site)
    end
  end
end
