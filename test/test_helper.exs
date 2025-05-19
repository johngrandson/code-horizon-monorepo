Mimic.copy(PetalPro.Notifications.UserMailer)
Mimic.copy(PetalPro.Billing.Providers.Stripe.Provider)
Mimic.copy(PetalPro.Billing.Providers.Stripe.Services.SyncSubscription)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PetalPro.Repo, :manual)

"screenshots/*"
|> Path.wildcard()
|> Enum.each(&File.rm/1)
