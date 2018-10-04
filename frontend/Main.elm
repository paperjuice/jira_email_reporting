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
  , subscriptions = (\_-> Sub.none)
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

type Msg
  = Decode (Result Http.Error String)
  | Username String
  | Password String
  | Base64
  | SprintKey String
  | Generate

type alias Model =
  { base64_key : String
  , username : String
  , password : String
  , storyKey : String
  }

init =
  (Model "" "" "" "", Cmd.none)

view model =
  case model.base64_key of
    "" -> div [ ]
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
    _ -> div [ ]
             [ div [ ] [ text "Add story-key from active sprint to generate Sprint Start Report" ]
             , div [ ] [ text "Add story-key from closed sprint to generate Sprint End Report" ]
             , div [ ]
                   [ input [ placeholder "e.g. ABC-123", onInput SprintKey ] [ ] 
                   ]
             , button [ onClick Generate ] [ text "Generate" ]
             ]

update msg model =
  case msg of
    Username string ->
      ({ model | username = string } |> Debug.log "hello", Cmd.none )

    Password string ->
      ({model | password = string }, Cmd.none )

    SprintKey string ->
      ({model | storyKey = string }, Cmd.none )

    Base64 ->
      let
          encoded = Base64.encode (model.username ++ ":" ++ model.password)
      in
      ({model | base64_key = encoded, username = "", password = "" }, Cmd.none)

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
          |> Debug.log "Response"
      in
      (model, Cmd.none)
