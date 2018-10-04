defmodule EmailReport do
  @moduledoc """
  Documentation for MailReport.
  """

  @base_url System.get_env("BASE_URL")
  @base_key_link System.get_env("BASE_KEY_LINK")
  @authorization System.get_env("AUTHORIZATION")

  def send_request(story) do
    headers = [Authorization: "Basic #{@authorization}"]

    [project, _] =
      story
      |> String.split("-")
      |> Enum.map(fn s ->
        String.trim(s)
      end)

    url = @base_url <> "/rest/api/2/search?jql=project=#{project}%20AND%20key=\"#{story}\""
    resp = HTTPoison.get!(url, headers, [])
    body = resp.body |> Poison.decode!()

    # TODO: Maybe use this 
    # status_code = resp.status_code

    fields = Kernel.hd(body["issues"])["fields"]
    sprint_list = Kernel.hd(body["issues"])["fields"]["customfield_10004"]
    last_sprint = List.last(sprint_list)

    "Swix " <> project_name = fields["project"]["name"]
    state = get_value(last_sprint, ~r/state=\w+/i)
    id = get_value(last_sprint, ~r/id=\d+/)
    start_date = get_value(last_sprint, ~r/startDate=[0-9-]+/)
    end_date = get_value(last_sprint, ~r/endDate=[0-9-]+/)
    goal = get_value(last_sprint, ~r/goal=[\w\d\=\-\(\)\*\& ]+/i)

    sprint_issue_list = get_sprint_data(project, id)

    case state do
      "ACTIVE" ->
        IO.puts(
          "Sprint active. Name: #{project_name}, ID: #{id}. StartDate: #{start_date} - EndDate: #{
            end_date
          } | Goal: #{goal}."
        )

        generate_active(sprint_issue_list, project_name, start_date, end_date, goal)

      "CLOSED" ->
        IO.puts(
          "Sprint closed. Name: #{project_name}, ID: #{id}. StartDate: #{start_date} - EndDate: #{
            end_date
          } | Goal: #{goal}."
        )

        generate_closed(sprint_issue_list, story, project_name, start_date, end_date, goal)

      unsupported ->
        IO.puts("Unsupported state: #{unsupported}. Contact whoever maintain this garbage.")
    end
  end

  # -----------------
  # PRIVATE
  # -----------------

  defp get_sprint_data(project, sprint_id) do
    url = @base_url <> "/rest/api/2/search?jql=project=#{project}%20AND%20Sprint=#{sprint_id}"
    # TODO: This is duplicate. Put it in one place
    headers = [Authorization: "Basic #{@authorization}"]
    resp = HTTPoison.get!(url, headers, [])

    Poison.decode!(resp.body)["issues"]
  end

  defp generate_closed(
         issues,
         story,
         project_name,
         start_date,
         end_date,
         goal
       ) do
    completed_stories =
      issues
      |> Enum.filter(fn issue ->
        is_done?(issue["fields"]["status"]["name"])
      end)
      |> Enum.map(fn issue ->
        %{
          "story_key" => issue["key"],
          "story_desc" => issue["fields"]["summary"],
          "story_link" => @base_key_link <> "/#{issue["key"]}",
          "story_status" => translate_status(issue["fields"]["status"]["name"]),
          "epic_name" => issue["fields"]["customfield_13305"],
          "epic_link" => get_epic_link(issue["fields"]["customfield_10005"])
        }
      end)

    ongoing_stories =
      issues
      |> Enum.filter(fn issue ->
        !is_done?(issue["fields"]["status"]["name"])
      end)
      |> Enum.map(fn issue ->
        %{
          "story_key" => issue["key"],
          "story_desc" => issue["fields"]["summary"],
          "story_link" => @base_key_link <> "/#{issue["key"]}",
          "story_status" => translate_status(issue["fields"]["status"]["name"]),
          "epic_name" => issue["fields"]["customfield_13305"],
          "epic_link" => get_epic_link(issue["fields"]["customfield_10005"])
        }
      end)

    result = [
      title: "Sprint End Report (#{get_date(start_date)}) - #{project_name}",
      project_name: project_name,
      sprint_start: start_date,
      sprint_end: end_date,
      goal: goal,
      completed_stories: completed_stories,
      ongoing_stories: ongoing_stories
    ]

    IO.inspect(result, label: Request)
    EEx.eval_file("priv/sprint_end.eex", result)
  end

  defp generate_active(
         issues,
         project_name,
         start_date,
         end_date,
         goal
       ) do
    active_data =
      Enum.map(issues, fn issue ->
        %{
          "story_key" => issue["key"],
          "story_desc" => issue["fields"]["summary"],
          "story_link" => @base_key_link <> "/#{issue["key"]}",
          "epic_name" => issue["fields"]["customfield_13305"],
          "epic_link" => get_epic_link(issue["fields"]["customfield_10005"])
        }
      end)

    result = %{
      title: "Sprint Start Report (#{get_date(start_date)}) - #{project_name}",
      project_name: project_name,
      sprint_start: start_date,
      sprint_end: end_date,
      goal: goal,
      issues: active_data
    }

    Poison.encode!(result)

    #    IO.inspect(result, label: Request)
    #    EEx.eval_file("priv/sprint_start.eex", result)
  end

  defp get_value(string, regex) do
    list = Regex.run(regex, string)

    case list do
      nil -> "No goal for this sprint."
      _ -> list |> Kernel.hd() |> String.split("=") |> List.last()
    end
  end

  defp get_epic_link(string) do
    case string do
      nil -> ""
      _ -> @base_key_link <> "/#{string}"
    end
  end

  defp get_date(start_date) do
    [year, month, day] =
      String.split(start_date, "-")
      |> IO.inspect(label: DATE)

    year = String.to_integer(year)
    month = String.to_integer(month)
    day = String.to_integer(day)
    datetime = Timex.to_date({year, month, day})
    {year, week_num, _day} = Timex.iso_triplet(datetime)

    "#{year}.#{week_num}"
  end

  defp is_done?(status) do
    if status in ["Done", "Ready for Release"],
      do: true,
      else: false
  end

  defp translate_status(status) do
    case status do
      "Done" -> "Released"
      "Ready for Release" -> "Pending for Deployment"
      _ -> status
    end
  end
end
