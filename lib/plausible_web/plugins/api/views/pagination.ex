defmodule PlausibleWeb.Plugins.API.Views.Pagination do
  use Phoenix.View,
    namespace: PlausibleWeb.Plugins.API,
    root: ""

  alias PlausibleWeb.Plugins.API.Router.Helpers

  def render_metadata_links(meta, helper_fn, helper_fn_args, existing_params \\ %{}) do
    render(__MODULE__, "pagination.json", %{
      meta: meta,
      url_helper: fn query_params ->
        existing_params = Map.drop(existing_params, ["before", "after"])

        query_params =
          query_params
          |> Enum.into(%{})
          |> Map.merge(existing_params)

        args = [PlausibleWeb.Plugins.API.base_uri() | List.wrap(helper_fn_args) ++ [query_params]]

        apply(Helpers, helper_fn, args)
      end
    })
  end

  @spec render(binary(), map()) ::
          binary()
  def render("pagination.json", %{meta: meta, url_helper: url_helper_fn}) do
    links =
      [
        {:after, :next, :has_next_page},
        {:before, :prev, :has_prev_page}
      ]
      |> Enum.reduce(%{}, fn
        {meta_key, url_key, sibling_key}, acc ->
          meta_value = Map.get(meta, meta_key)

          if meta_value do
            url = url_helper_fn.([{meta_key, meta_value}])

            acc
            |> Map.put(url_key, %{url: url})
            |> Map.put(sibling_key, true)
          else
            Map.put(acc, sibling_key, false)
          end
      end)

    %{
      pagination: %{_links: links}
    }
  end
end
