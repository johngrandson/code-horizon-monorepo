defmodule PetalPro.Accounts.Permissions do
  @moduledoc """
  One place to change role permissions.
  """

  def can_impersonate?(nil, _) do
    false
  end

  def can_impersonate?(_, nil) do
    false
  end

  def can_impersonate?(user, current_user) do
    PetalPro.config(:impersonation_enabled?) && !(user.role == :admin) && user.id != current_user.id
  end

  def can_access_admin_routes?(nil) do
    false
  end

  def can_access_admin_routes?(current_user) do
    current_user.role == :admin
  end

  def can_access_user_profiles?(nil) do
    false
  end

  def can_access_user_profiles?(current_user) do
    current_user.role == :admin
  end
end
