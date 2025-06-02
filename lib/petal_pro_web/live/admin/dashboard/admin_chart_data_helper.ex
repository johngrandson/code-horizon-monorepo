defmodule PetalProWeb.AdminChartDataHelper do
  @moduledoc false
  import Ecto.Query, warn: false

  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Repo

  def get_active_subscriptions do
    subscriptions =
      from(s in Subscriptions.list_subscriptions_query(), where: s.status == "active")
      |> Repo.all()
      |> Enum.group_by(& &1.plan_id)

    labels = Enum.map(subscriptions, fn {plan_id, _} -> plan_id end)

    data =
      Enum.map(subscriptions, fn {_plan_id, subscriptions} ->
        Enum.count(subscriptions)
      end)

    label_count = Enum.count(labels)

    datasets = [
      %{
        data: data,
        backgroundColor: [hue: 0.5] |> Util.ColorStream.hex() |> Enum.take(label_count) |> Enum.map(&"##{&1}"),
        hoverBackgroundColor: Util.ColorStream.hex() |> Enum.take(label_count) |> Enum.map(&"##{&1}"),
        borderColor: "transparent"
      }
    ]

    %{
      labels: labels,
      datasets: datasets,
      empty?: empty?(datasets)
    }
  end

  def get_this_month_and_last_months_data(query) do
    beginning_of_month = Timex.beginning_of_month(DateTime.utc_now())
    end_of_month = Timex.end_of_month(DateTime.utc_now())

    {this_months_data, this_months_labels} = get_insertion_counts_by_day(query, beginning_of_month, end_of_month)

    last_month_start = DateTime.utc_now() |> Timex.shift(months: -1) |> Timex.beginning_of_month()
    last_month_end = DateTime.utc_now() |> Timex.shift(months: -1) |> Timex.end_of_month()

    {last_months_data, _} = get_insertion_counts_by_day(query, last_month_start, last_month_end)

    datasets = [
      %{
        data: this_months_data,
        labels: this_months_labels,
        borderColor: "#10b981"
      },
      %{
        data: last_months_data,
        borderColor: "rgb(0 0 0 / 15%)"
      }
    ]

    total_for_this_month = Enum.reduce(this_months_data, 0, fn x, acc -> (x || 0) + acc end)
    total_for_last_month = Enum.reduce(last_months_data, 0, fn x, acc -> (x || 0) + acc end)

    day_of_the_month = DateTime.utc_now().day

    total_at_this_day_last_month =
      last_months_data
      |> Enum.with_index()
      |> Enum.reduce(0, fn {x, i}, acc ->
        if i <= day_of_the_month, do: acc + x, else: acc
      end)

    # Need to watch out for dividing by 0, which causes a crash
    percentage_change =
      if total_at_this_day_last_month > 0 do
        increase = total_for_this_month - total_at_this_day_last_month
        round(increase / total_at_this_day_last_month * 100)
      else
        if total_for_this_month > 0 do
          100
        else
          0
        end
      end

    %{
      labels: this_months_labels,
      datasets: datasets,
      empty?: empty?(datasets),
      total_for_this_month: total_for_this_month,
      total_for_last_month: total_for_last_month,
      percentage_change: percentage_change
    }
  end

  def get_this_year_and_last_years_data(query) do
    beginning_of_year = Timex.beginning_of_year(DateTime.utc_now())
    end_of_year = Timex.end_of_year(DateTime.utc_now())

    {this_years_data, this_years_labels} = get_insertion_counts_by_month(query, beginning_of_year, end_of_year)

    last_year_start = DateTime.utc_now() |> Timex.shift(years: -1) |> Timex.beginning_of_year()
    last_year_end = DateTime.utc_now() |> Timex.shift(years: -1) |> Timex.end_of_year()

    {last_years_data, _} = get_insertion_counts_by_month(query, last_year_start, last_year_end)

    datasets = [
      %{
        data: this_years_data,
        label: "This year",
        backgroundColor: "rgba(3, 105, 161, 0.9)",
        hoverBackgroundColor: "rgba(3, 105, 161, 1)",
        barPercentage: 0.66,
        categoryPercentage: 0.66,
        borderWidth: 2,
        borderColor: "rgba(3, 105, 161, 0.9)",
        useGradient: true,
        fill: true,
        gradientFrom: "rgba(3, 105, 161, 0.9)",
        gradientTo: "rgba(3, 105, 161, 0)"
      },
      %{
        data: last_years_data,
        label: "Last year",
        backgroundColor: "rgba(125, 211, 252, 0.9)",
        hoverBackgroundColor: "rgba(125, 211, 252, 1)",
        barPercentage: 0.66,
        categoryPercentage: 0.66,
        borderWidth: 2,
        borderColor: "rgba(125, 211, 252, 0.9)",
        useGradient: true,
        fill: true,
        gradientFrom: "rgba(125, 211, 252, 0.9)",
        gradientTo: "rgba(125, 211, 252, 0)"
      }
    ]

    total_for_this_year = Enum.reduce(this_years_data, 0, fn x, acc -> (x || 0) + acc end)
    total_for_last_year = Enum.reduce(last_years_data, 0, fn x, acc -> (x || 0) + acc end)

    month_of_the_year = DateTime.utc_now().month

    total_at_this_month_last_year =
      last_years_data
      |> Enum.with_index()
      |> Enum.reduce(0, fn {x, i}, acc ->
        if i <= month_of_the_year, do: acc + x, else: acc
      end)

    # Need to watch out for dividing by 0, which causes a crash
    percentage_change =
      if total_at_this_month_last_year > 0 do
        increase = total_for_this_year - total_at_this_month_last_year
        round(increase / total_at_this_month_last_year * 100)
      else
        if total_for_this_year > 0 do
          100
        else
          0
        end
      end

    %{
      labels: this_years_labels,
      datasets: datasets,
      empty?: empty?(datasets),
      total_for_this_year: total_for_this_year,
      total_for_last_year: total_for_last_year,
      percentage_change: percentage_change
    }
  end

  defp get_insertion_counts_by_day(query, start_date, end_date) do
    daily_counts = query |> insertion_counts_grouped_by_day(start_date, end_date) |> Repo.all()

    number_of_days = Timex.diff(end_date, start_date, :days)

    data =
      Enum.map(0..number_of_days, fn day ->
        day_as_date = start_date |> Timex.shift(days: day) |> Timex.to_date()

        case Enum.find(daily_counts, fn {daily_count_date, _count} ->
               daily_count_date == day_as_date
             end) do
          nil ->
            if Timex.before?(day_as_date, DateTime.utc_now()), do: 0

          {_, count} ->
            count
        end
      end)

    labels =
      Enum.map(0..number_of_days, fn day ->
        start_date
        |> Timex.shift(days: day)
        |> Timex.to_date()
        |> Timex.format!("Day {D}/#{number_of_days}")
      end)

    {data, labels}
  end

  defp get_insertion_counts_by_month(query, start_date, end_date) do
    monthly_counts = query |> insertion_counts_grouped_by_month(start_date, end_date) |> Repo.all()

    number_of_months = 11

    data =
      Enum.map(0..number_of_months, fn month ->
        month_as_date = start_date |> Timex.shift(months: month) |> Timex.to_date()

        case Enum.find(monthly_counts, fn {_, monthly_count_date, _count} ->
               monthly_count_date == month_as_date
             end) do
          nil ->
            if Timex.before?(month_as_date, DateTime.utc_now()), do: 0

          {_, _, count} ->
            count
        end
      end)

    labels =
      Enum.map(0..number_of_months, fn month ->
        start_date
        |> Timex.shift(months: month)
        |> Timex.to_date()
        |> Timex.format!("%m-%Y", :strftime)
      end)

    {data, labels}
  end

  defp insertion_counts_grouped_by_day(query, start_date, end_date) do
    from u in query,
      select: {
        fragment("date_trunc('day', ?)::date", u.inserted_at),
        count(u.id)
      },
      group_by: fragment("date_trunc('day', ?)::date", u.inserted_at),
      where: u.inserted_at >= ^start_date,
      where: u.inserted_at <= ^end_date,
      order_by: [asc: fragment("date_trunc('day', ?)::date", u.inserted_at)]
  end

  defp insertion_counts_grouped_by_month(query, start_date, end_date) do
    from u in query,
      select: {
        fragment("date_trunc('year', ?)::date", u.inserted_at),
        fragment("date_trunc('month', ?)::date", u.inserted_at),
        count(u.id)
      },
      group_by: [
        fragment("date_trunc('year', ?)::date", u.inserted_at),
        fragment("date_trunc('month', ?)::date", u.inserted_at)
      ],
      where: u.inserted_at >= ^start_date,
      where: u.inserted_at <= ^end_date,
      order_by: [asc: fragment("date_trunc('month', ?)::date", u.inserted_at)]
  end

  defp empty?(datasets) when is_list(datasets) do
    Enum.empty?(datasets) or
      Enum.all?(datasets, fn dataset ->
        Enum.empty?(dataset.data) or Enum.all?(dataset.data, fn value -> value in [nil, 0] end)
      end)
  end
end
