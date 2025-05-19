# Pricing/plan page

## Initial purchase

1. User chooses a plan and clicks "Get plan"
2. Create Stripe session to get redirect url
3. Redirect to Stripe
4. Purchase is successful (failed payments never return)
5. Stripe redirects to success page and calls web hook
6. Web hook is used to create Petal Pro Customer data with Stripe Customer data
7. Success page is updated with status of web hook. If hook completes before success page is rendered, then it displays current info

## Change plan

1. Selected plan button will be disabled and should show "Current Plan"
2. Other buttons show "Switch plan"
3. User chooses an alternative and clicks "Switch plan"
4. Create Stripe session and get redirect url
5. Redirect to Stripe
6. Purchase is successful (failed payments never return)
7. Stripe redirects to success page and calls web hook
8. Web hook is used to _update_ Petal Pro Customer data with Stripe Customer data
9. Success page is updated with status of web hook. If hook completes before success page is rendered, then it displays current info

## Notes

Most of the UI will be implemented in `PetalProWeb.PlansComponent`. Which means that any page can display subscription/plan pricing. However, each page will need to implement its own plumbing.

This plumbing will be a workflow that's based on Stripe (as a starting point). But it will be expanded to other payment services (e.g. Paddle, Square and maybe others?). Therefore it makes sense to (attempt) to abstract this code and make it reuseable.

Potentially, this could be a similar to the pattern that was implemented for image uploads. A lot of thought was put into the image uploads - in terms of ease of use, making choices obvious and how you might copy that code to another page.

# Subscription protected pages

## User accesses route with valid purchase/subscription

1. User navigates to route
2. Plug that sets subscription assign finds valid record (that exists and is within a date range)
3. Valid subscription assigns is set
4. Plug that checks for subscription assign succeeds
5. User gets to see page

## User accesses route without purchase/subscription

1. User navigates to route
2. Plug that sets subscription assign does not find valid record (either it does not exist or it's outside a date range)
3. Subscription assign is not set
4. Plug that checks for subscription fails and redirects

## Menus/navigation

Subscription protected routes should be added the relevant menus/navigation!

## Notes

Plug that loads Subscription record can retrieve sub one of two ways. Either, from a User (that belongs to an Org with only 1 user) or from an Org
