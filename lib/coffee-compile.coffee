url         = require 'url'
querystring = require 'querystring'

CoffeeCompileView = require './coffee-compile-view'
util              = require './util'

module.exports =
  configDefaults:
    grammars: [
      'source.coffee'
      'source.litcoffee'
      'text.plain'
      'text.plain.null-grammar'
    ]
    noTopLevelFunctionWrapper: true
    compileOnSave: false
    compileOnSaveWithoutPreview: false
    focusEditorAfterCompile: false

  activate: ->
    atom.workspaceView.command 'coffee-compile:compile', => @display()

    if atom.config.get('coffee-compile.compileOnSaveWithoutPreview')
      atom.workspaceView.command 'core:save', => @save()

    atom.workspace.addOpener (uriToOpen) ->
      {protocol, pathname} = url.parse uriToOpen
      pathname = querystring.unescape(pathname) if pathname

      return unless protocol is 'coffeecompile:'

      new CoffeeCompileView
        sourceEditorId: pathname.substr(1)

  checkGrammar: (editor) ->
    grammars = atom.config.get('coffee-compile.grammars') or []
    return (grammar = editor.getGrammar().scopeName) in grammars

  save: ->
    editor = atom.workspace.getActiveEditor()

    return unless editor?

    return unless @checkGrammar editor

    util.compileToFile editor

  display: ->
    editor     = atom.workspace.getActiveEditor()
    activePane = atom.workspace.getActivePane()

    return unless editor?

    unless @checkGrammar editor
      return console.warn("Cannot compile non-Coffeescript to Javascript")

    atom.workspace.open "coffeecompile://editor/#{editor.id}",
      searchAllPanes: true
      split: "right"
