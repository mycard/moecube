maotama = angular.module 'maotama', [
  'ngRoute',
  'maotama.filters',
  'maotama.services',
  'maotama.directives',
  'maotama.controllers'
]

maotama.config ['$routeProvider',($routeProvider)->
  $routeProvider
  .when '/apps/:app_id',
      templateUrl: 'partials/app_show.html',
      controller: 'AppsShowController'
  .otherwise
      redirectTo:'/apps/th123'
]