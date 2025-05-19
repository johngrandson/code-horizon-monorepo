defmodule PetalPro.Posts.PostSeeder do
  @moduledoc false
  alias PetalPro.Posts

  def create_posts(user) do
    blog_post(user)
    cms_post(user)
  end

  def blog_post(user) do
    attrs = %{
      title: "Add analytics to your Phoenix Live View app",
      category: "LiveView",
      summary:
        "It can be difficult to know where to put analytics tracking code on your Phoenix Live View web application. Snippets like Google Analytics don't work with Live Views due to the lack of page refreshes.",
      author_id: user.id,
      cover: "https://res.cloudinary.com/wickedsites/image/upload/f_auto,h_960/sulzrdaa7cdixgtxwniv",
      cover_caption: "Analytics - everybodies favourite activity",
      content: """
      {"time":1733381128734,"blocks":[{"id":"q6WN-_LNsF","type":"paragraph","data":{"text":"Recently I was trying to add Go Squared (a Google Analytics competitor) to our Phoenix Live View application and realised it wasn’t going to work due to the lack of page reloading."}},{"id":"nP2TknoUEx","type":"paragraph","data":{"text":"Usually, the analytics snippet does something like this:"}},{"id":"ksOxvsFJyU","type":"code","data":{"code":"ga('send', 'pageview');"}},{"id":"SqemKhKYQF","type":"paragraph","data":{"text":"Live views don’t make a normal HTTP request (they use websockets) and thus when a user goes from one live route to another the analytics javascript snippet doesn’t run."}},{"id":"b_tc7sJbnh","type":"paragraph","data":{"text":"Instead, we need to hook into the live view lifecycle. Create a new file next to your&nbsp;<code>app.js</code>&nbsp;file:&nbsp;<code>analytics.js</code>."}},{"id":"jS13SqEyCZ","type":"paragraph","data":{"text":"In your app.js:"}},{"id":"jmWVcR1YyU","type":"code","data":{"code":"import \\"phoenix_html\\";\\nimport { Socket } from \\"phoenix\\";\\nimport { LiveSocket } from \\"phoenix_live_view\\";\\nimport topbar from \\"../vendor/topbar\\";\\nimport Hooks from \\"./hooks\\";\\nimport \\"./analytics.js\\"; // <--- Add this"}},{"id":"0-wZcJUIig","type":"paragraph","data":{"text":"Then in you analytics.js:"}},{"id":"qc695H6Cbm","type":"code","data":{"code":"function trackPageView() {\\n   yourAnalytics.page();\\n}\\n\\nwindow.addEventListener(\\"phx:page-loading-stop\\", () => {\\n  // When someone goes to a different live view page:\\n  trackPageView();\\n});\\n\\n// Run for non-live views\\ntrackPageView();"}},{"id":"51W0JzoIB2","type":"paragraph","data":{"text":"This mostly works, except I found when doing a live redirect the&nbsp;<code>trackPageView()</code>&nbsp;function was running twice! I have no idea if it was something to do with my app or a live view issue. To fix, I put the last page into a variable, and be sure not to double up with the page views:"}},{"id":"CwojbyFjVs","type":"code","data":{"code":"window.lastPage = \\"\\";\\n\\nfunction trackPageView() {\\n  let pageNotYetTracked = lastPage != window.location.pathname;\\n\\n  if (pageNotYetTracked) {\\n    yourAnalytics.page();\\n  }\\n   window.lastPage = window.location.pathname;\\n}\\n\\nwindow.addEventListener(\\"phx:page-loading-stop\\", () => {\\n  // When someone goes to a different live view page:\\n  trackPageView();\\n});\\n\\n// Run for non-live views\\ntrackPageView();"}},{"id":"_bwFIbWMrq","type":"paragraph","data":{"text":"Now it only gets called once per page!"}},{"id":"X1OgR0q48u","type":"paragraph","data":{"text":"Article <a href=\\"https://petal.build/blog/Add-analytics-to-your-Phoenix-Live-View-app\\">source</a>"}}],"version":"2.30.6"}
      """,
      duration: 1
    }

    {:ok, %{post: post}} = Posts.create_post(attrs)
    {:ok, post} = Posts.publish_post(post, %{"go_live" => DateTime.utc_now()})

    post
  end

  def cms_post(user) do
    attrs = %{
      title: "Getting started with the CMS",
      category: "Announcement",
      summary: "Petal Pro now comes with a Content Management System. This comes with an out-of-the-box Blog feature.",
      author_id: user.id,
      cover:
        "https://res.cloudinary.com/wickedsites/image/upload/v1733440121/petal_marketing/blog/EDITOR/connor-home-7Qpp39GHY3w-unsplash_1_sia0tp.jpg",
      cover_caption: "Become one with the content",
      content: """
      {"time":1733445479541,"blocks":[{"id":"B0axkdV8gy","type":"header","data":{"text":"Introduction","level":2}},{"id":"dzDXtUKMkg","type":"paragraph","data":{"text":"Now you can create your own Blog posts and be in control of your content with your own server. The main features of the CMS are:"}},{"id":"Cjquq5fy6Q","type":"list","data":{"style":"unordered","items":["Manage posts via the admin console","Auto-save enabled - so you don't accidentally lose hours of work","Publishing process means that you can edit data in multiple sessions, without affecting live content","Data entry is based on <a href=\\"https://editorjs.io\\">Editor.js</a> - a block editor that provides a means to edit rich content","File browser provides means to upload and select images - making it easy to honour the Content Security Policy","Extensible - the CMS is easy to understand. Modify it for your own means"]}},{"id":"UW3-VXV1yz","type":"header","data":{"text":"What can I do with Editor.js?","level":2}},{"id":"P_Q7Xv1QgO","type":"paragraph","data":{"text":"The previous section demonstrated headings, paragraphs and lists. You can add an image (which can be managed by the file browser):"}},{"id":"8M3KBTNVOS","type":"petalImage","data":{"url":"https://res.cloudinary.com/wickedsites/image/upload/v1733447705/petal_marketing/blog/EDITOR/oskars-sylwan-rcAOIMSDfyc-unsplash_1_ckmkqe.jpg","caption":"Out of nowhere"}},{"id":"NqJn0HrSZc","type":"paragraph","data":{"text":"You can <mark class=\\"cdx-marker\\">highlight parts</mark> of your text."}},{"id":"bJalOouocl","type":"paragraph","data":{"text":"You can add a quote:"}},{"id":"_XoFDt1Jtp","type":"quote","data":{"text":"Be Water, My Friend. Empty your mind. Be formless, shapeless, like water. You put water into a cup, it becomes the cup. You put water into a bottle, it becomes the bottle. You put it into a teapot, it becomes the teapot. Now water can flow or it can crash. Be water, my friend.","caption":"- Bruce Lee","alignment":"left"}},{"id":"Cio7OqjOgU","type":"paragraph","data":{"text":"Or even create a table:"}},{"id":"w_cNMZnerD","type":"table","data":{"withHeadings":true,"content":[["One","Cats 🐱","Dogs 🐶"],["Social Behaviour","Independent; often solitary","Pack animals; thrive on companionship"],["Trainability","Less trainable; respond to rewards","Highly trainable with consistent effort"],["Exercise Needs","Low; self-exercise indoors","High; require daily walks and play"]]}},{"id":"1QYCVBzSRH","type":"header","data":{"text":"Extending Editor.js","level":2}},{"id":"gA_1fePK4z","type":"paragraph","data":{"text":"Editor.js is quite extensible - it has a healthy plug-in eco-system. If there's something the editor doesn't do, then there's probably a plug-in for that. For more on this topic, see <a href=\\"https://docs.petal.build/petal-pro-documentation/guides/content-editor-adding-your-own-plug-in\\">Content Editor - adding your own plug-in</a>."}},{"id":"80LOfhzR88","type":"warning","data":{"title":"Editor.js is easy to use and flexible - but it has limitations","message":"Though Editor.js is generally easy to use and is pleasant to deal with from a coding point of view, it does have it's quirks. Unfortunately, answers to these problems live with Editor.js (rather than Petal Pro)"}},{"id":"CWkOSS3ay6","type":"paragraph","data":{"text":"If a plug-in has a quirk or it doesn't have the right behaviour - the only option may be to contribute to that plug-in (either by providing feedback or by contributing code)."}},{"id":"8_LgCREOyA","type":"header","data":{"text":"Where to from here?","level":2}},{"id":"MaAX5VArYh","type":"paragraph","data":{"text":"Why not start by heading on over to the <a href=\\"/admin/posts\\">admin console</a>. Good luck and happy blogging!"}}],"version":"2.30.6"}
      """,
      duration: 2
    }

    {:ok, %{post: post}} = Posts.create_post(attrs)
    {:ok, post} = Posts.publish_post(post, %{"go_live" => DateTime.add(DateTime.utc_now(), 10, :hour)})

    post
  end
end
