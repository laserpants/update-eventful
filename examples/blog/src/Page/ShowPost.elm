module Page.ShowPost exposing (..)

import Data.Comment as Comment exposing (Comment)
import Data.Post as Post exposing (Post)
import Form exposing (Form)
import Form.Comment
import Helpers exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Update.Deep exposing (..)
import Update.Deep.Api as Api
import Update.Deep.Form
import Update.Deep.Form as Form

type Msg 
  = PostApiMsg (Api.Msg Post)
  | CommentApiMsg (Api.Msg Comment)
  | FetchPost
  | CommentFormMsg Form.Msg

type alias State =
  { id : Int
  , post : Api.Model Post 
  , comment : Api.Model Comment
  , commentForm : Form.Model Never Form.Comment.Fields }

inPostApi : In State (Api.Model Post) msg a
inPostApi =
    inState { get = .post, set = \state post -> { state | post = post } }

inCommentApi : In State (Api.Model Comment) msg a
inCommentApi =
    inState { get = .comment, set = \state comment -> { state | comment = comment } }

inCommentForm : In State (Form.Model Never Form.Comment.Fields) msg a
inCommentForm =
    inState { get = .commentForm, set = \state form -> { state | commentForm = form } }

init : Int -> (Msg -> msg) -> Update State msg a
init id toMsg = 

  let
      post = Api.init { endpoint = "/posts/" ++ String.fromInt id
                      , method   = Api.HttpGet
                      , decoder  = Json.field "post" Post.decoder }

      comment = Api.init { endpoint = "/posts/" ++ String.fromInt id ++ "/comments"
                         , method   = Api.HttpPost
                         , decoder  = Json.field "comment" Comment.decoder }
   in 
      save State
        |> andMap (save id)
        |> andMap post
        |> andMap comment
        |> andMap (Form.init [] Form.Comment.validate)
        |> mapCmd toMsg

handleSubmit : (Msg -> msg) -> Form.Comment.Fields -> State -> Update State msg a
handleSubmit toMsg form state = 

  let 
      json = form |> Form.Comment.toJson state.id |> Http.jsonBody 
   in 
      state 
        |> inCommentApi (Api.sendRequest "" (Just json) (toMsg << CommentApiMsg))

update : { onCommentCreated : Comment -> a } -> Msg -> (Msg -> msg) -> State -> Update State msg a
update { onCommentCreated } msg toMsg = 

  let 
      toApiMsg = toMsg << PostApiMsg

      commentCreated comment = 
        inCommentForm (Form.reset [])
          >> andThen (inPostApi (Api.sendSimpleRequest toApiMsg))
          >> andInvokeHandler (onCommentCreated comment)
   in 
      case msg of
        PostApiMsg apiMsg ->
          inPostApi (Api.update { onSuccess = always save, onError = always save } apiMsg toApiMsg)
        FetchPost ->
          inPostApi (Api.sendSimpleRequest toApiMsg)
        CommentFormMsg formMsg ->
          inCommentForm (Update.Deep.Form.update { onSubmit = handleSubmit toMsg } formMsg)
        CommentApiMsg apiMsg ->
          inCommentApi (Api.update { onSuccess = commentCreated, onError = always save } apiMsg (toMsg << CommentApiMsg))

subscriptions : State -> (Msg -> msg) -> Sub msg
subscriptions state toMsg = Sub.none

commentsView : List Comment -> (Msg -> msg) -> Html msg
commentsView comments toMsg =

  let
      commentItem comment =
        div [] 
          [ div [ style "margin-bottom" ".5em" ] [ b [] [ text "From: " ], text comment.email ]
          , div [] [ p [] [ text comment.body ] ]
          , hr [] [] 
          ]
   in
      if List.isEmpty comments
          then 
            p [ class "content" ] [ text "No comments" ]
          else
            div [] (List.map commentItem comments)

view : State -> (Msg -> msg) -> Html msg
view { post, comment, commentForm } toMsg = 
 div [ class "columns is-centered", style "margin" "1.5em" ] 
   [ div [ class "column is-two-thirds" ] 
     [ if Api.Requested == post.resource || commentForm.disabled
           then
             spinner
           else
             case post.resource of
               Api.Error error ->
                 apiResourceErrorMessage post.resource
               Api.Available post_ -> 
                 div []
                   [ h3 
                     [ class "title is-3" ] [ text post_.title ] 
                     , p [ class "content" ] [ text post_.body ]
                     , hr [] []
                     , h5 [ class "title is-5" ] [ text "Comments" ] 
                     , commentsView post_.comments toMsg
                     , h5 [ class "title is-5" ] [ text "Leave a comment" ] 
                     , apiResourceErrorMessage comment.resource
                     , Form.Comment.view commentForm.form commentForm.disabled (toMsg << CommentFormMsg)
                     ]
               _ ->
                 text ""
     ]
   ]