import Html exposing (div, span, Html, text, button, input, br)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (type_, placeholder)
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

type alias SprintStart =
  { title : String
  , start : String
  , sprint_goal : String
  , project_name : String
  , end : String
  , issues : List Issue
  }

type alias Issue =
  { story_link : String
  , story_key : String
  , story_desc : String
  , epic_name : String
  , epic_link : String
  }
type alias SprintType =
  { sprint_type : String
  }

sprintStartDecoder =
  decode SprintStart
  |> required "title" string
  |> required "project_name" string
  |> required "sprint_start" string
  |> required "sprint_end" string
  |> required "goal" string
  |> required "issues" (list issuesDecoder)

issuesDecoder =
  decode Issue
  |> required "story_key" string
  |> required "story_desc" string
  |> required "story_link" string
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
  | EndSprint
  | StartSprint 

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
    EndSprint -> viewEndSprint model
    StartSprint -> viewStartSprint model


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
  div [ ]
      [ 
      ]

viewStartSprint : Model -> Html msg
viewStartSprint model =
  div [ ]
      [ 
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
  
          data = Decode.decodeString sprintEndDecoder response 
          resp = case data of
            Ok data -> data
            _ -> (SprintEnd "smthing's f**ked up :)" "" "" "" "" [] [])

      in
      ({ model | sprintEnd = resp }, Cmd.none)

subscriptions model =
  Sub.none
