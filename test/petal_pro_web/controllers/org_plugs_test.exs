defmodule PetalProWeb.OrgPlugsTest do
  use PetalProWeb.ConnCase, async: true

  setup :register_and_sign_in_user

  setup do
    other_user = PetalPro.AccountsFixtures.confirmed_user_fixture(%{is_onboarded: true})
    other_org = PetalPro.OrgsFixtures.org_fixture(other_user)

    {:ok, other_org: other_org}
  end

  test "navigates to org if the user has access", %{conn: conn, org: org} do
    conn = get(conn, ~p"/app/org/#{org.slug}")
    assert html_response(conn, 200) =~ org.name
  end

  test "redirects if user cannot access org (or org does not exist)", %{
    conn: conn,
    other_org: other_org
  } do
    conn = get(conn, ~p"/app/org/#{other_org.slug}")
    assert conn.halted
    assert redirected_to(conn) == ~p"/app/orgs"
  end
end
