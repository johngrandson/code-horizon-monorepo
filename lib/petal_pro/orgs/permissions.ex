defmodule PetalPro.Orgs.Permissions do
  @moduledoc """
  Handles organization permissions for various features.
  """

  alias PetalPro.Orgs

  def can_receive_merchandise?(org_id) do
    case Orgs.get_org_by_id(org_id) do
      %{plan: :free} -> true
      _ -> false
    end
  end

  def can_receive_footer_news?(org_id) do
    case Orgs.get_org_by_id(org_id) do
      %{status: :active, plan: plan} when plan in [:free, :starter, :professional] ->
        true

      _ ->
        false
    end
  end

  def can_receive_premium_features?(org_id) do
    case Orgs.get_org_by_id(org_id) do
      %{status: :active, plan: plan} when plan in [:professional, :enterprise] ->
        true

      _ ->
        false
    end
  end
end
