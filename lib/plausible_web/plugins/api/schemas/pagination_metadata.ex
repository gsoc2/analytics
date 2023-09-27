defmodule PlausibleWeb.Plugins.API.Schemas.PaginationMetadata do
  @moduledoc """
  Pagination metadata OpenAPI schema
  """
  use PlausibleWeb, :open_api_schema

  OpenApiSpex.schema(%{
    title: "PaginationMetadata",
    description: "Pagination meta data",
    type: :object,
    required: [:_links],
    properties: %{
      _links: %OpenApiSpex.Schema{
        items: Schemas.Link,
        required: [:has_next_page, :has_prev_page],
        properties: %{
          has_next_page: %OpenApiSpex.Schema{type: :boolean},
          has_prev_page: %OpenApiSpex.Schema{type: :boolean},
          next: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Link"},
          prev: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Link"}
        },
        type: :object
      }
    }
  })
end
