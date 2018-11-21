--port module Main exposing (main)
import Html.Styled exposing (div, span, Html, text, button, input, br, a, ul, li, toUnstyled, img)
import Base64
import Http
import Css exposing (color, rgb)
import Html
import Html.Styled.Events exposing (onClick, onInput)
import Html.Styled.Attributes exposing (type_, placeholder, class, href, css, src, value, attribute, id)

import Json.Decode as Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)

--port copy : String -> Cmd msg

main =
  Html.program
  { init = init
  , update = update
  , view = view >> toUnstyled
  , subscriptions = subscriptions
  }

url = "http://localhost:9999/email-report/"
emailAddresses = ""

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
  , name : String
  , start : String
  , end : String
  , sprint_goal : String
  , completed_stories : List CompletedStory
  , ongoing_stories : List OngoingStory
  }

type alias CompletedStory =
  { story_key : String
  , story_desc : String
  , story_link : String
  , story_status : String
  , epic_name : String
  , epic_link : String
  }

type alias OngoingStory =
  { story_key : String
  , story_desc : String
  , story_link : String
  , story_status : String
  , epic_name : String
  , epic_link : String
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
  | Back

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
  , loading : Bool
  }

------------------
-- INIT
------------------
init =
  (Model "" "" "" "" (SprintStart "" "" "" "" "" []) (SprintEnd "" "" "" "" "" [] []) Login False, Cmd.none)

------------------------------------------------------------------------
--                         CSS
------------------------------------------------------------------------

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
  div [ class "login" ]
      [ div [ ] 
            [ img [ src "https://builderscollege.edu.in/wp-content/uploads/2016/11/EMAILICON.png" ]  [ ]
            ]
      , div [ ]
            [ input [ onInput Username, placeholder "Username", value model.username] [ ]
            ]
      , div [ ]
            [ input [ type_ "Password", onInput Password, placeholder "Password", value model.password ] [ ]
            ]
      , div [ class "login_button" ]
            [ button [ onClick Base64 ] [ text "Authenticate" ]
            ]
      ]

viewLoadingIcon : Bool -> Html msg
viewLoadingIcon loading =
  if loading == True then
    img [ class "loading", src "derivco_cat.svg"] [ ]
  else
    div [ ] [ ]
viewEnterKey : Model -> Html Msg
viewEnterKey model =
  div [ class "enter_key" ]
      [ div [ class "title" ] [ text "Steps to generate report" ]
      , div [ class "step1"]
            [ text "All you have to do is copy a story key (e.g. ABC-23) in the input field below."]
      , div [ class "line"] [ ]
      , div [ class "step2" ] [ text "For sprint start report, copy a story key from the current sprint."]
      , div [ class "or" ] [ text "OR" ]
      , div [ class "step3"] [ text "For sprint end report, copy a FINISHED story key from the ended sprint."]
      , div [ class "key_input" ]
            [ input [ placeholder "ABC-123", onInput SprintKey ] [ ] 
            ]
      , div [ class "generate_button" ]
            [ button [ onClick Generate ] [ text "Generate" ]
            ]
      , viewLoadingIcon model.loading
      ]

viewEndSprint : Model -> Html Msg
viewEndSprint model =
  let
      e = model.sprintEnd
  in
      div []
          [ div [ class "generated" ] [ text "Generated Sprint End report" ]
          , div [ class "back", onClick Back ] [ text "<"]
          , div [ class "e", id "copy" ] 
                [ span [ class "e_start_1" ] [ text "Start: " ]
                , span [ class "e_start_2" ] [ text (e.start ++ " |") ]
                , span [ class "e_end_1" ] [ text "  End: " ]
                , span [ class "e_end_2" ] [ text e.end ]
                , div [ ] [ ]
                , span [ class "e_goal" ] [ text "Sprint Goal: "] 
                , span [ ] [ text e.sprint_goal]
                , br [ ] [ ]
                , br [ ] [ ]
                , div [ class "e_comp_stories" ]
                      [ text "List of completed stories: " ]
                , ul [ ] (listOfCompletedStories e.completed_stories )
                , br [ ] [ ]
                , div [ class "e_ongoing_stories" ]
                      [ text "List of not completed stories" ]
                , ul [ ] (listOfOngoingStories e.ongoing_stories)
                , br [ ] [ ]
                , br [ ] [ ]
                , div [ class "regards" ] [ text "Kind regards," ]
                ]
          , div [ class "mail-to" ]
                [ a [ class "button", id "mailto", href ("mailto:" ++ emailAddresses ++ "?subject=" ++ e.title), attribute "data-clipboard-target" "#copy" ] [ text "Open e-mail :)" ] 
                ]
          ]

listOfCompletedStories : List OngoingStory -> List (Html msg)
listOfCompletedStories issues =
 List.map(\ issue ->
   li [ ]
       [ a [class "i_key", href issue.story_link ] [ text issue.story_key ]
       , span [ class "i_desc" ] [ text (" | " ++ issue.story_desc ++ " | ") ]
       , buildEpic issue.epic_link issue.epic_name
       , span [ class "i_status" ] [ text (" | " ++ issue.story_status) ]
       ]
   ) issues

listOfOngoingStories : List OngoingStory -> List (Html msg)
listOfOngoingStories issues =
  case issues of
    [] -> [ li [ ] [ text "All issues were completed!" ] ]
    _  -> List.map(\ issue ->
         li [ ]
             [ a [class "i_key", href issue.story_link ] [ text issue.story_key ]
             , span [ class "i_desc" ] [ text (" | " ++ issue.story_desc ++ " | ") ]
             , buildEpic issue.epic_link issue.epic_name
             , span [ class "i_status" ] [ text (" | " ++ issue.story_status) ]
             ]
         ) issues

viewStartSprint : Model -> Html Msg
viewStartSprint model =
  let
      s = model.sprintStart
  in
      div [ ]
          [ div [ class "generated" ] [ text "Generated Sprint Start report" ]
          , div [ class "back", onClick Back ] [ text "<"]
          , div [ class "e", id "copy"] 
                [ span [ class "e_start_1" ] [ text "Start: " ]
                , span [ class "e_start_2" ] [ text (s.start ++ " |")]
                , span [ class "e_end_1" ] [ text " End: " ]
                , span [ class "e_end_2" ] [ text s.end ]
                , div [ ] [ ]
                , span [ class "e_goal" ] [ text "Sprint Goal: "] 
                , span [ ] [ text s.sprint_goal]
                , br [ ] [ ]
                , br [ ] [ ]
                , div [ class "e_comp_stories" ]
                      [ text "List of committed stories: " ]
                , ul [ ] (listOfCommitedStories s.issues)
                , br [ ] [ ]
                , div [ class "capacity" ] [ text "Capacity: " ]
                , div [ class "capacity_desc" ] [ text "All team members are available." ]
                , br [ ] [ ]
                , div [ class "risk" ] [ text "Risks: " ]
                , div [ class "risk_desc" ] [ text "No known risks." ]
                , br [ ] [ ]
                , br [ ] [ ]
                , div [ class "regards" ] [ text "Kind regards," ]
                ]
          , div [ class "mail-to" ]
                [ a [ class "button", id "mailto", href ("mailto:" ++ emailAddresses ++ "?subject=" ++ s.title), attribute "data-clipboard-target" "#copy" ] [ text "Open e-mail :)" ] 
                ]
          ]

listOfCommitedStories : List Issue -> List (Html msg)
listOfCommitedStories issues =
  List.map (\ issue -> 
    li [ ]
        [ a [class "i_key", href issue.story_link ] [ text issue.story_key ]
        , span [ class "i_desc" ] [ text (" | " ++ issue.story_desc ++ " | ") ]
        , buildEpic issue.epic_link issue.epic_name
        ]
    ) issues

buildEpic : String -> String -> Html msg
buildEpic link name =
  case name of
    "No Epic" -> span [ class "i_epic" ] [ text name ]
    _ -> a [ class "i_epic", href link ] [ text name ]
  
    
viewError : Model -> Html msg
viewError model =
  div [ class "error"]
      [ div [ class "e1" ] [ text "Oh no, stuff's broken :("]
      , div [ class "e2" ] [ text "Make sure your password is correct." ]
      , div [ class "e2" ] [ text "Make sure your password is not expired." ]
      , div [ class "e3" ] [ text "Make sure Jira is not locked behind CAPCHA. Pop on the JIRA's login page and try to log in." ]
      , div [ class "e3" ] [ text "Make sure your key exist." ]
      , div [ class "e2" ] [ text "Sometimes you can get timeouts from JIRA." ]
      ]

------------------
-- UPDATE
------------------
update msg model =
  case msg of
    Back ->
      ( {model | screen = EnterKey}, Cmd.none)
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
      ({model | loading = True}, command)

    Decode result ->
      let
          response =
            case result of
              Ok json -> json
              Err msg -> toString(msg)
  
          sType = 
            case (Decode.decodeString sprintTypeDecoder response) of
              Ok sprint_type -> sprint_type
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
                 screen = screen,
                 loading = False
      }, Cmd.none)
      
subscriptions model =
  Sub.none
