defmodule PetalProWeb.UserOrgInvitationsLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.OrgsFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Orgs.Invitation
  alias PetalPro.Repo

  setup :register_and_sign_in_user

  describe "when invitations are present" do
    test "when invitations are present can accept an invitation", %{conn: conn, user: user} do
      new_org = org_fixture()
      invitation_fixture(new_org, %{email: user.email})
      {:ok, view, html} = live(conn, ~p"/app/users/org-invitations")
      assert html =~ new_org.name
      assert Repo.count(Invitation) == 1

      result =
        view
        |> element("button", "Accept")
        |> render_click()

      assert {:error, {:redirect, %{to: redirect_url}}} = result
      assert redirect_url == "/app/org/#{new_org.slug}"

      assert_log("orgs.accept_invitation", %{user_id: user.id, org_id: new_org.id})
      assert Repo.count(Invitation) == 0
    end

    test "can reject an invitation", %{conn: conn, user: user, org: _org} do
      new_org = org_fixture()
      invitation_fixture(new_org, %{email: user.email})
      {:ok, view, html} = live(conn, ~p"/app/users/org-invitations")
      assert html =~ new_org.name
      assert Repo.count(Invitation) == 1

      html =
        view
        |> element("button", "Reject")
        |> render_click()

      assert html =~ "Invitation was rejected"

      assert_log("orgs.reject_invitation", %{user_id: user.id, org_id: new_org.id})
      assert Repo.count(Invitation) == 0
    end
  end

  describe "when there are no invitations" do
    test "lets the user know there are none", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/app/users/org-invitations")

      assert view |> element("h3.pc-h3", "No Pending Invitations") |> has_element?()

      empty_state = view |> element("div.mt-6.py-12.bg-white") |> render()
      assert empty_state =~ "No Pending Invitations"
      assert empty_state =~ "pending organization invitations"
      assert empty_state =~ "hero-user-plus"
    end
  end
end
