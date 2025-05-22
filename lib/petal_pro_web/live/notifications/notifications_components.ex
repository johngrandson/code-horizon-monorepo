defmodule PetalProWeb.Notifications.Components do
  @moduledoc """
  Components relevant to the app notification bell dropdown.
  """
  use PetalProWeb, :component
  use PetalComponents

  import PetalProWeb.Helpers

  alias PetalPro.Accounts.User
  alias PetalPro.Notifications.UserNotification

  attr :idx, :integer, required: true, doc: "The index of the notification in the list."
  attr :notification, :map, required: true, doc: "The notification to render."

  def notification_item(%{notification: %UserNotification{type: :invited_to_org}} = assigns) do
    ~H"""
    <.link
      href={~p"/app/users/org-invitations"}
      class="flex p-2 transition-colors rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
    >
      <.avatar
        random_color
        name={user_name(@notification.sender)}
        src={user_avatar_url(@notification.sender)}
        class="shrink-0"
      />
      <div class="flex flex-col my-auto ml-4 space-y-1 text-sm text-gray-700 dark:text-gray-100">
        <p>
          {gettext("%{name} invited you to join the %{org_name} organization.",
            name: "<span class='font-medium'>#{get_sender_name(@notification.sender)}</span>",
            org_name: "<span class='font-medium'>#{@notification.org.name}</span>"
          )
          |> raw()}
        </p>
        <p class="text-xs text-gray-500">{humanized_time_since(@notification.inserted_at)}</p>
      </div>
      <span class="grow" />
      <span
        :if={is_nil(@notification.read_at)}
        class="shrink-0 w-2 h-2 my-auto mr-2 bg-red-500 rounded-full"
      />
    </.link>
    """
  end

  def get_sender_name(%User{} = user), do: user_name(user)
  def get_sender_name(_), do: gettext("Someone")

  defp humanized_time_since(naive_dt_since) do
    utc_since = DateTime.from_naive!(naive_dt_since, "Etc/UTC")
    utc_now = DateTime.utc_now()
    duration_start = Timex.Duration.from_seconds(DateTime.to_unix(utc_since))
    duration_end = Timex.Duration.from_seconds(DateTime.to_unix(utc_now))
    seconds_diff = Timex.Duration.diff(duration_end, duration_start, :seconds)

    time_since(duration_start, duration_end, seconds_diff)
  end

  defp time_since(_, _, seconds_diff) when seconds_diff < 60 do
    gettext("Just now")
  end

  defp time_since(duration_start, duration_end, seconds_diff) when seconds_diff < 3600 do
    case Timex.Duration.diff(duration_end, duration_start, :minutes) do
      1 -> gettext("1 minute ago")
      minutes_since -> gettext("%{no_of_minutes} minutes ago", no_of_minutes: minutes_since)
    end
  end

  defp time_since(duration_start, duration_end, seconds_diff) when seconds_diff < 86_400 do
    case Timex.Duration.diff(duration_end, duration_start, :hours) do
      1 -> gettext("1 hour ago")
      hours_since -> gettext("%{no_of_hours} hours ago", no_of_hours: hours_since)
    end
  end

  defp time_since(duration_start, duration_end, seconds_diff) when seconds_diff < 604_800 do
    case Timex.Duration.diff(duration_end, duration_start, :days) do
      1 -> gettext("1 day ago")
      days_since -> gettext("%{no_of_days} days ago", no_of_days: days_since)
    end
  end

  defp time_since(duration_start, duration_end, _seconds_diff) do
    case Timex.Duration.diff(duration_end, duration_start, :weeks) do
      1 -> gettext("1 week ago")
      weeks_since -> gettext("%{no_of_weeks} weeks ago", no_of_weeks: weeks_since)
    end
  end
end
