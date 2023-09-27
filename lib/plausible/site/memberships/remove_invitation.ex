defmodule Plausible.Site.Memberships.RemoveInvitation do
  @moduledoc """
  Service for removing invitations.
  """

  alias Plausible.Auth
  alias Plausible.Repo
  alias Plausible.Site.Memberships.Invitations

  @spec remove_invitation(String.t(), Plausible.Site.t()) ::
          {:ok, Auth.Invitation.t()} | {:error, :invitation_not_found}
  def remove_invitation(invitation_id, site) do
    with {:ok, invitation} <- Invitations.find_for_site(invitation_id, site) do
      Repo.delete!(invitation)

      {:ok, invitation}
    end
  end
end
