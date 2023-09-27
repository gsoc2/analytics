defmodule PlausibleWeb.Plugins.API.Spec do
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, Server}
  alias PlausibleWeb.Plugins.API.Router
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        %Server{
          description: "Local server",
          url: "http://localhost:8000/api/plugins",
          variables: %{}
        }
      ],
      info: %Info{
        title: "Plausible Plugins API",
        version: "1.0-rc"
      },
      # Populate the paths from a phoenix router
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "basic_auth" => %OpenApiSpex.SecurityScheme{
            type: "http",
            scheme: "basic",
            description: """
            HTTP basic access authentication using your Site domain as the
            username and the Plugins API Token contents as the password.

            For more information see
            https://en.wikipedia.org/wiki/Basic_access_authentication
            """
          }
        }
      },
      security: [%{"basic_auth" => []}]
    }
    # Discover request/response schemas from path specs
    |> OpenApiSpex.resolve_schema_modules()
  end
end
