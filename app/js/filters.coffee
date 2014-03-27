languages = require './js/languages.json'
humanize = require 'humanize'
markdown = require( "markdown" ).markdown;


angular.module('maotama.filters', [])
.filter 'language_translate', ()->
  (input)->
    languages[input]
.filter 'filesize', ()->
    humanize.filesize
.filter 'markdown', ()->
    (input)->
      markdown.toHTML(input) if input