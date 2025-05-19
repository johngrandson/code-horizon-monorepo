# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PetalPro.Repo.insert!(%PetalPro.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias PetalPro.Accounts.User
alias PetalPro.Accounts.UserSeeder
alias PetalPro.Accounts.UserToken
alias PetalPro.Accounts.UserTOTP
alias PetalPro.Files.File
alias PetalPro.Files.FileSeeder
alias PetalPro.Logs.Log
alias PetalPro.Orgs.Invitation
alias PetalPro.Orgs.Membership
alias PetalPro.Orgs.Org
alias PetalPro.Orgs.OrgSeeder
alias PetalPro.Posts.Post
alias PetalPro.Posts.PostSeeder

if Mix.env() == :dev do
  PetalPro.Repo.delete_all(Log)
  PetalPro.Repo.delete_all(UserTOTP)
  PetalPro.Repo.delete_all(Invitation)
  PetalPro.Repo.delete_all(Membership)
  PetalPro.Repo.delete_all(Org)
  PetalPro.Repo.delete_all(UserToken)
  PetalPro.Repo.delete_all(User)
  PetalPro.Repo.delete_all(Post)
  PetalPro.Repo.delete_all(File)

  admin = UserSeeder.admin()

  normal_user =
    UserSeeder.normal_user(%{
      email: "user@example.com",
      name: "Sarah Cunningham",
      password: "password",
      confirmed_at: Timex.to_naive_datetime(DateTime.utc_now())
    })

  UserSeeder.fake_subscription(normal_user)

  org = OrgSeeder.random_org(admin)
  PetalPro.Orgs.create_invitation(org, %{email: normal_user.email})

  UserSeeder.random_users(20)

  FileSeeder.create_files(admin)
  PostSeeder.create_posts(admin)
end
