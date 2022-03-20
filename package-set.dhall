let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
in [
    { name = "testing"
    , version = "master" -- TODO: replace with fixed version.
    , repo = "https://github.com/internet-computer/testing"
    , dependencies = [] : List Text
    }
] : List Package
