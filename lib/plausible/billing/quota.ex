defmodule Plausible.Billing.Quota do
  @moduledoc """
  This module provides functions to work with plans usage and limits.
  """

  import Ecto.Query
  alias Plausible.Billing.Plans

  @limit_sites_since ~D[2021-05-05]
  @spec site_limit(Plausible.Auth.User.t()) :: non_neg_integer() | :unlimited
  @doc """
  Returns the limit of sites a user can have.

  For enterprise customers, returns :unlimited. The site limit is checked in a
  background job so as to avoid service disruption.
  """
  def site_limit(user) do
    cond do
      Application.get_env(:plausible, :is_selfhost) -> :unlimited
      Timex.before?(user.inserted_at, @limit_sites_since) -> :unlimited
      true -> get_site_limit_from_plan(user)
    end
  end

  @site_limit_for_trials 50
  @site_limit_for_free_10k 50
  defp get_site_limit_from_plan(user) do
    user = Plausible.Users.with_subscription(user)

    case Plans.get_subscription_plan(user.subscription) do
      %Plausible.Billing.EnterprisePlan{} -> :unlimited
      %Plausible.Billing.Plan{site_limit: site_limit} -> site_limit
      :free_10k -> @site_limit_for_free_10k
      nil -> @site_limit_for_trials
    end
  end

  @spec site_usage(Plausible.Auth.User.t()) :: non_neg_integer()
  @doc """
  Returns the number of sites the given user owns.
  """
  def site_usage(user) do
    Plausible.Sites.owned_sites_count(user)
  end

  @monthly_pageview_limit_for_free_10k 10_000
  @monthly_pageview_limit_for_trials :unlimited

  @spec monthly_pageview_limit(Plausible.Billing.Subscription.t()) ::
          non_neg_integer() | :unlimited
  @doc """
  Returns the limit of pageviews for a subscription.
  """
  def monthly_pageview_limit(subscription) do
    case Plans.get_subscription_plan(subscription) do
      %Plausible.Billing.EnterprisePlan{monthly_pageview_limit: limit} ->
        limit

      %Plausible.Billing.Plan{monthly_pageview_limit: limit} ->
        limit

      :free_10k ->
        @monthly_pageview_limit_for_free_10k

      _any ->
        if subscription do
          Sentry.capture_message("Unknown monthly pageview limit for plan",
            extra: %{paddle_plan_id: subscription.paddle_plan_id}
          )
        end

        @monthly_pageview_limit_for_trials
    end
  end

  @spec monthly_pageview_usage(Plausible.Auth.User.t()) :: non_neg_integer()
  @doc """
  Returns the amount of pageviews sent by the sites the user owns in last 30 days.
  """
  def monthly_pageview_usage(user) do
    user
    |> Plausible.Billing.usage_breakdown()
    |> Tuple.sum()
  end

  @team_member_limit_for_trials 5
  @spec team_member_limit(Plausible.Auth.User.t()) :: non_neg_integer()
  @doc """
  Returns the limit of team members a user can have in their sites.
  """
  def team_member_limit(user) do
    user = Plausible.Users.with_subscription(user)

    case Plans.get_subscription_plan(user.subscription) do
      %Plausible.Billing.EnterprisePlan{} -> :unlimited
      %Plausible.Billing.Plan{team_member_limit: limit} -> limit
      :free_10k -> :unlimited
      nil -> @team_member_limit_for_trials
    end
  end

  @spec team_member_usage(Plausible.Auth.User.t()) :: integer()
  @doc """
  Returns the total count of team members and pending invitations associated
  with the user's sites.
  """
  def team_member_usage(user) do
    team_members_query =
      from os in subquery(owned_sites_query(user)),
        inner_join: sm in Plausible.Site.Membership,
        on: sm.site_id == os.site_id,
        inner_join: u in assoc(sm, :user),
        select: %{email: u.email}

    invitations_and_team_members_query =
      from i in Plausible.Auth.Invitation,
        inner_join: os in subquery(owned_sites_query(user)),
        on: i.site_id == os.site_id,
        where: i.role != :owner,
        select: %{email: i.email},
        union: ^team_members_query

    query =
      from itm in subquery(invitations_and_team_members_query),
        where: itm.email != ^user.email,
        select: count(itm.email, :distinct)

    Plausible.Repo.one(query)
  end

  @spec extra_features_usage(Plausible.Auth.User.t()) :: [atom()]
  @doc """
  Returns a list of extra features the given user's sites uses.
  """
  def extra_features_usage(user) do
    props_usage_query =
      from s in Plausible.Site,
        inner_join: os in subquery(owned_sites_query(user)),
        on: s.id == os.site_id,
        select: fragment("cardinality(?) > 0", s.allowed_event_props)

    funnels_usage_query =
      from f in Plausible.Funnel,
        inner_join: os in subquery(owned_sites_query(user)),
        on: f.site_id == os.site_id,
        select: count(f) > 0

    revenue_goals_usage =
      from g in Plausible.Goal,
        inner_join: os in subquery(owned_sites_query(user)),
        on: g.site_id == os.site_id,
        where: not is_nil(g.currency),
        select: count(g) > 0

    queries = [
      props: props_usage_query,
      funnels: funnels_usage_query,
      revenue_goals: revenue_goals_usage
    ]

    Plausible.Repo.transaction(fn ->
      Enum.reduce(queries, [], fn {feature, query}, acc ->
        if Plausible.Repo.one(query), do: [feature | acc], else: acc
      end)
    end)
  end

  defp owned_sites_query(user) do
    from sm in Plausible.Site.Membership,
      where: sm.role == :owner and sm.user_id == ^user.id,
      select: %{site_id: sm.site_id}
  end

  @spec within_limit?(non_neg_integer(), non_neg_integer() | :unlimited) :: boolean()
  @doc """
  Returns whether the limit has been exceeded or not.
  """
  def within_limit?(usage, limit) do
    if limit == :unlimited, do: true, else: usage < limit
  end
end
