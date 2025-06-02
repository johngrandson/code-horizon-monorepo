defmodule PetalProWeb.OrgsLiveTest do
  use PetalProWeb.ConnCase

  import Phoenix.LiveViewTest

  alias PetalPro.Repo

  setup :register_and_sign_in_user

  describe ":index action" do
    test "show orgs the user is a member of", %{conn: conn, org: org} do
      {:ok, _view, html} = live(conn, ~p"/app/orgs")
      assert html =~ org.name
    end
  end

  # describe "not org admin" do
  #   test "it redirects", %{conn: conn, org: _org, user: _user} do
  #     assert {:error, {:redirect, %{flash: %{"error" => "You do not have permission to access this page."}}}} =
  #              live(conn, ~p"/app/orgs/new")
  #   end
  # end

  # describe "org admin" do
  #   setup :register_and_sign_in_admin

  #   test "it allows", %{conn: conn, org: _org, user: _user} do
  #     assert {:ok, _view, html} = live(conn, ~p"/app/orgs/new")
  #     assert html =~ "New Organization"
  #   end
  # end

  describe ":new action" do
    setup :register_and_sign_in_admin

    test "with valid params will create a new org with timestamped slug", %{conn: conn, org: _org, user: _user} do
      {:ok, view, html} = live(conn, ~p"/app/orgs/new")

      assert html =~ "New Organization"

      {:ok, _view, html} =
        view
        |> form("form", org: %{name: "Acme Inc."})
        |> render_submit()
        |> follow_redirect(conn, ~p"/app/orgs")

      assert html =~ "Acme Inc."

      org = Repo.last(PetalPro.Orgs.Org)
      assert org.name == "Acme Inc."

      # Check that the slug follows the pattern "acme-inc-TIMESTAMP"
      assert org.slug =~ "acme-inc-"

      # Extract the timestamp from the slug
      [base_slug, timestamp_str] =
        org.slug |> String.split("-", parts: 3) |> Enum.chunk_every(2) |> Enum.map(&Enum.join(&1, "-"))

      assert base_slug == "acme-inc"

      # Ensure the timestamp is a valid integer
      {timestamp, _} = Integer.parse(timestamp_str)

      # Verify the timestamp is recent (within the last minute)
      current_time = System.system_time(:second)
      assert current_time - timestamp < 60
    end
  end
end
