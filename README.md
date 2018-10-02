# EmailReporting

## Intro
EmailReporting is a primitive tool for generating reports for beggining and ending of a sprint.
These reports have a specific format and are supposed to be copied and pasted in an email which can be sent to people within the organisation. The templates can be found under ```priv/```.

## Installation
1. Clone the repo
``` git clone https://github.com/paperjuice/jira_email_reporting.git```

2. Add environment variables
```
BASE_URL="https://jira.atlassian.com"
BASE_KEY_LINK="https://jira.atlassian.com/browse"
AUTHORIZATION="randomstring="
EMAIL="first_last01@mail.com; first_last02@mail.com"
```
BASE_URL is your organisation's JIRA</br>
AUTHORIZATION string can be generated from the Elixir interactive shell(```iex()>```) by running: 
```Base.encode64("username:password")```</br>
The project uses the basic authorization method.

3. Run```iex -S mix```</br>
By default the app listens on port 9999. You can configure this in ```lib/application.ex```

## Usage
You need to access ```localhost:9999/email-report/<story-key>``` which will generate the the appropriate report: end or start of sprint.</br>
Story-key, in my case, is something of the shape ABC-123.</br>
The application assumes your story key is comeposed of ```<something>-<something>```</br>
1. By providing an arbitrary story key from an ended sprint, the app generates a "Closed sprint" report.
2. By providing an arbitrary story key from an active sprint, the app generates an "Open sprint" report.

## Bugs
This projects was written in quite a short time and I didn't give it too much thought which makes it very very likely to be filled with issues. Let me know if you encounter any.
