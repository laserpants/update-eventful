module App.Auth.Login.Form exposing (..)

import Form exposing (Form)
import Json.Encode as Encode exposing (Value, object)
import Update.Form exposing (Fields, Msg(..))

type alias LoginForm =
  { login    : String
  , password : String }

fields : Fields LoginForm
fields =

  let loginField =
        Form.textField
          { parser = Ok
          , value  = .login
          , update = \value values -> { values | login = value }
          , attributes =
            { label       = "Login"
            , placeholder = "Login" } }

      passwordField =
        Form.passwordField
          { parser = Ok
          , value  = .password
          , update = \value values -> { values | password = value }
          , attributes =
            { label       = "Password"
            , placeholder = "Your password" } }

   in Form.succeed LoginForm
    |> Form.append loginField
    |> Form.append passwordField
    |> Form.map Submit

toJson : LoginForm -> Value
toJson { login, password } =
  object [ ( "login"    , Encode.string login )
         , ( "password" , Encode.string password ) ]
