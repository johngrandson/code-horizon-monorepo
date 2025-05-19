defmodule PetalPro.StripeApiResponses do
  @moduledoc false
  def mocked_subscription_response(opts \\ []) do
    subscription_id = opts[:subscription_id] || "sub_1NtX3iIWVkWpNCp7eVTUtPrH"

    {:ok,
     %Stripe.Subscription{
       id: subscription_id,
       object: "subscription",
       application_fee_percent: nil,
       automatic_tax: %{enabled: false},
       billing_cycle_anchor: 1_695_480_230,
       billing_thresholds: nil,
       collection_method: "charge_automatically",
       cancel_at: nil,
       cancel_at_period_end: false,
       canceled_at: nil,
       currency: "aud",
       created: 1_695_480_230,
       current_period_end: 1_698_072_230,
       current_period_start: 1_695_480_230,
       customer: opts[:customer] || "cus_OgutAdgqdPY5h1",
       days_until_due: nil,
       default_payment_method: "pm_1NtX3hIWVkWpNCp7DDRiGWmY",
       default_source: nil,
       default_tax_rates: [],
       discount: nil,
       ended_at: nil,
       items: %Stripe.List{
         object: "list",
         data: [
           %Stripe.SubscriptionItem{
             id: "si_OgutTtqt1hquLf",
             object: "subscription_item",
             billing_thresholds: nil,
             created: 1_695_480_231,
             metadata: %{},
             plan: %Stripe.Plan{
               id: "price_1NLhPDIWVkWpNCp7trePDpmi",
               object: "plan",
               active: true,
               aggregate_usage: nil,
               amount: 2700,
               amount_decimal: "2700",
               billing_scheme: "per_unit",
               created: 1_687_416_851,
               currency: "aud",
               interval: "month",
               interval_count: 1,
               livemode: false,
               metadata: %{},
               nickname: nil,
               product: "prod_O7xJu8gX3GeCIp",
               tiers: nil,
               tiers_mode: nil,
               transform_usage: nil,
               trial_period_days: nil,
               usage_type: "licensed"
             },
             price: %Stripe.Price{
               id: "item1-1-1",
               object: "price",
               active: true,
               billing_scheme: "per_unit",
               created: 1_687_416_851,
               currency: "aud",
               livemode: false,
               lookup_key: nil,
               metadata: %{},
               nickname: nil,
               product: "prod_O7xJu8gX3GeCIp",
               recurring: %{
                 interval: "month",
                 aggregate_usage: nil,
                 interval_count: 1,
                 trial_period_days: nil,
                 usage_type: "licensed"
               },
               tax_behavior: "exclusive",
               tiers: nil,
               tiers_mode: nil,
               transform_quantity: nil,
               type: "recurring",
               unit_amount: 2700,
               unit_amount_decimal: "2700"
             },
             quantity: 1,
             subscription: subscription_id,
             tax_rates: []
           }
         ],
         has_more: false,
         total_count: 1,
         url: "/v1/subscription_items?subscription=sub_1NtX3iIWVkWpNCp7eVTUtPrH"
       },
       latest_invoice: "in_1NtX3iIWVkWpNCp7tnABYBYz",
       livemode: false,
       metadata: %{
         "plan" => "business_monthly",
         "source" => opts[:source] || "user",
         "source_id" => opts[:source_id] || 1,
         "user_id" => opts[:user_id] || 1
       },
       next_pending_invoice_item_invoice: nil,
       pending_invoice_item_interval: nil,
       pending_setup_intent: nil,
       pending_update: nil,
       pause_collection: nil,
       schedule: nil,
       start_date: 1_695_480_230,
       status: "active",
       test_clock: nil,
       transfer_data: nil,
       trial_end: nil,
       trial_start: nil
     }}
  end

  def mocked_update_subscription_session_response(customer_id) do
    {:ok,
     %Stripe.BillingPortal.Session{
       id: "bps_1O8g6dIWVkWpNCp7z2QttdFS",
       object: "billing_portal.session",
       created: 1_699_089_927,
       configuration: "bpc_1LwAeVIWVkWpNCp7GeTAHWm3",
       customer: customer_id,
       livemode: false,
       return_url: nil,
       url:
         "https://billing.stripe.com/p/session/test_YWNjdF8xS1FOeVVJV1ZrV3BOQ3A3LF9Pd1pGQ0FmQ3JTVThSTm9NVjdtSm5NYk1lZzhhanBO0100yJM8Bezy/flow"
     }}
  end
end
