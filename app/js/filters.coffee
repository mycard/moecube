languages = require './js/languages.json'
humanize = require 'humanize'

angular.module('maotama.filters', [])
.filter 'language_translate', ()->
  (input)->
    languages[input]
.filter 'filesize', ()->
    humanize.filesize
