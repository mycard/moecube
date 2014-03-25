# Directives 还不知道怎么玩，下面是默认的
angular.module("maotama.directives", [])
.directive "appVersion", [
  "version"
  (version) ->
    return (scope, elm, attrs) ->
      elm.text version
      return
]