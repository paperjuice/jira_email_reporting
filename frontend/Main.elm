import Html exposing (div, span, Html, text, button, input, br, a)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (type_, placeholder, class, href)
import Base64
import Http

import Json.Decode as Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


main =
  Html.program
  { init = init
  , update = update
  , view = view
  , subscriptions = subscriptions
  }

url = "http://localhost:9999/email-report/"

type alias SprintType =
  { sprint_type : String
  }

sprintTypeDecoder =
  decode SprintType
  |> required "sprint_type" string

-- START SPRINT --
type alias SprintStart =
  { title : String
  , start : String
  , end : String
  , sprint_goal : String
  , project_name : String
  , issues : List Issue
  }

type alias Issue =
  { story_link : String
  , story_key : String
  , story_desc : String
  , epic_name : String
  , epic_link : String
  }

sprintStartDecoder =
  decode SprintStart
  |> required "title" string
  |> required "sprint_start" string
  |> required "sprint_end" string
  |> required "goal" string
  |> required "project_name" string
  |> required "issues" (list issuesDecoder)

issuesDecoder =
  decode Issue
  |> required "story_link" string
  |> required "story_key" string
  |> required "story_desc" string
  |> required "epic_name" string
  |> required "epic_link" string

-- END SPRINT --
type alias SprintEnd=
  { title : String
  , projectName : String
  , sprintStart : String
  , sprintEnd : String
  , goal : String
  , completedStories : List CompletedStory
  , ongoingStories : List OngoingStory
  }

type alias CompletedStory =
  { storyKey : String
  , storyDesc : String
  , storyLink : String
  , storyStatus : String
  , epicName : String
  , epicLink : String
  }

type alias OngoingStory =
  { storyKey : String
  , storyDesc : String
  , storyLink : String
  , storyStatus : String
  , epicName : String
  , epicLink : String
  }

sprintEndDecoder =
  decode SprintEnd
  |> required "title" string
  |> required "project_name" string
  |> required "sprint_start" string
  |> required "sprint_end" string
  |> required "goal" string
  |> required "completed_stories" (list storyDecoder)
  |> required "ongoing_stories" (list storyDecoder)

storyDecoder =
  decode OngoingStory
  |> required "story_key" string
  |> required "story_desc" string
  |> required "story_link" string
  |> required "story_status" string
  |> required "epic_name" string
  |> required "epic_link" string

type Msg
  = Decode (Result Http.Error String)
  | Username String
  | Password String
  | Base64
  | SprintKey String
  | Generate

type Screen
  = Login
  | EnterKey
  | SEnd
  | SStart
  | Error

type alias Model =
  { base64_key : String
  , username : String
  , password : String
  , storyKey : String
  , sprintStart : SprintStart
  , sprintEnd : SprintEnd
  , screen : Screen
  }

------------------
-- INIT
------------------
init =
  (Model "" "" "" "" (SprintStart "" "" "" "" "" []) (SprintEnd "" "" "" "" "" [] []) Login, Cmd.none)

------------------
-- VIEW
------------------
view model =
  case model.screen of
    Login -> viewLogin model
    EnterKey -> viewEnterKey model
    SEnd -> viewEndSprint model
    SStart -> viewStartSprint model
    Error -> viewError model


viewLogin : Model -> Html Msg
viewLogin model =
  div [ ]
      [ div [ ]
            [  span [ ] [ text "Username: " ]
            ,  input [ onInput Username ] [ ]
            ]
      , div [ ]
            [ span [ ] [ text "Password: " ]
            , input [ type_ "Password", onInput Password ] [ ]
            ]
      , br [ ] [ ]
      , div [ ]
            [ button [ onClick Base64 ] [ text "Authenticate" ]
            ]
      ]

viewEnterKey : Model -> Html Msg
viewEnterKey model =
  div [ ]
      [ div [ ] [ text "Add story-key from active sprint to generate Sprint Start Report" ]
      , div [ ] [ text "Add story-key from closed sprint to generate Sprint End Report" ]
      , div [ ]
            [ input [ placeholder "e.g. ABC-123", onInput SprintKey ] [ ] 
            ]
      , button [ onClick Generate ] [ text "Generate" ]
      ]

viewEndSprint : Model -> Html msg
viewEndSprint model =
  let
      sprintStart = model.sprintStart
  in
      div [ ]
          [ div [ ] [ text "S" ]
          , div [ ] [ ]
          ]

viewStartSprint : Model -> Html msg
viewStartSprint model =
  let
      s = model.sprintStart
      |> Debug.log "sSprint"
  in
      div [ ]
          [ span [ class "s_start_1" ] [ text "Start: " ]
          , span [ class "s_start_2" ] [ text s.start ]
          , span [ class "s_end_1" ] [ text "End: " ]
          , span [ class "s_end_2" ] [ text s.end ]
          , div [ class "s_goal" ] [ text ("Sprint Goal: " ++ s.sprint_goal)]
          , div [ class "s_comm_stories" ]
                [ text "List of committed stories: " ]
          , div [ ] (listOfCommitedStories s.issues)
          , div [ class "s_capacity" ] [ text "Capacity: " ]
          , div [ class "s_capacity_desc" ] [ text "All team members are available." ]
          , div [ class "s_risk" ] [ text "Risks: " ]
          , div [ class "s_risk_desc" ] [ text "No known risks." ]
          , div [ class "s_regards" ] [ text "Kind regards," ]
          ]

listOfCommitedStories : List Issue -> List (Html msg)
listOfCommitedStories issues =
  List.map (\ issue -> 
    div [ ]
        [ span [ class "i_bp" ] [ text "*" ] 
        , a [class "i_key", href issue.story_link ] [ text issue.story_key ]
        , span [ class "i_desc" ] [ text ("| " ++ issue.story_desc ++ " | ") ]
        , buildEpic issue.epic_link issue.epic_name
        ]
    ) issues

buildEpic : String -> String -> Html msg
buildEpic link name =
  case (Debug.log "" name) of
    "No Epic" -> span [ class "i_epic" ] [ text name ]
    _ -> a [ class "i_epic", href link ] [ text name ]
  
    
viewError : Model -> Html msg
viewError model =
  div [ ]
      [ text "Error"
      ]

------------------
-- UPDATE
------------------
update msg model =
  case msg of
    Username string ->
      ({ model | username = string }, Cmd.none )

    Password string ->
      ({model | password = string }, Cmd.none )

    SprintKey string ->
      ({model | storyKey = string }, Cmd.none )

    Base64 ->
      let
          encoded = Base64.encode (model.username ++ ":" ++ model.password)
      in
      ({model | base64_key = encoded, username = "", password = "", screen = EnterKey }, Cmd.none)

    Generate ->
      let
          headers =
            [ Http.header "Basic" model.base64_key
            ]

          req = Http.request
            { method = "GET"
            , headers = headers
            , url = url ++ model.storyKey
            , body = Http.emptyBody
            , expect = Http.expectString
            , timeout = Nothing
            , withCredentials = False
            }

          command = Http.send Decode req
      in
      (model, command)

    Decode result ->
      let
          response =
            case result of
              Ok json -> json
              Err msg -> toString(msg)
  
          sType = 
            case (Decode.decodeString sprintTypeDecoder response) of
              Ok sprint_type -> sprint_type |> Debug.log "type"
              _ -> SprintType "oups"

          screen =
            case sType.sprint_type of
              "start_sprint" -> SStart
              "end_sprint"   -> SEnd
              _ -> Error

          end =
            case Decode.decodeString sprintEndDecoder response of
              Ok data -> data
              _       -> (SprintEnd "" "" "" "" "" [] [])

          start =
            case Decode.decodeString sprintStartDecoder response of
              Ok data -> data
              _       -> (SprintStart "" "" "" "" "" [])

      in
      ({ model | sprintEnd = end,
                 sprintStart = start,
                 screen = screen
      }, Cmd.none)

subscriptions model =
  Sub.none
