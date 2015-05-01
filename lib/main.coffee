url         = require 'url'
querystring = require 'querystring'

CoffeeCompileEditor = require './coffee-compile-editor'
util                = require './util'
pluginManager       = require './plugin-manager'
coffeeProvider      = require './coffee-provider'

module.exports =
  config:
    noTopLevelFunctionWrapper:
      type: 'boolean'
      default: true
    compileOnSave:
      type: 'boolean'
      default: false
    compileOnSaveWithoutPreview:
      type: 'boolean'
      default: false
    focusEditorAfterCompile:
      type: 'boolean'
      default: false
    compileCjsx:
      type: 'boolean'
      default: false
      description: 'Provides support for an equivalent of JSX syntax in Coffeescript'
      title: 'Compile CJSX'
    destination:
      type: 'string'
      default: '.'
      title: 'Destination filepath'
      description: 'Relative to project root'
    flatten:
      type: 'boolean'
      default: false
      description: 'Remove all path parts'

  activate: ->
    saveDisposable = null

    atom.commands.add 'atom-workspace', 'coffee-compile:compile': => @display()

    atom.config.observe 'coffee-compile.compileOnSaveWithoutPreview', (value) =>
      if not value and saveDisposable?
        saveDisposable.dispose()
        saveDisposable = null

      else if value
        saveDisposable = atom.commands.add 'atom-workspace', 'core:save': => @save()

    # NOTE: Remove once coffeescript provider is moved to a new package
    @registerProviders coffeeProvider

    atom.workspace.addOpener (uriToOpen) ->
      {protocol, pathname} = url.parse uriToOpen
      pathname = querystring.unescape(pathname) if pathname

      return unless protocol is 'coffeecompile:'

      sourceEditorId = pathname.substr(1)
      sourceEditor   = util.getTextEditorById sourceEditorId

      return unless sourceEditor?

      return new CoffeeCompileEditor {sourceEditor}

  save: ->
    editor = atom.workspace.getActiveTextEditor()

    if editor? and pluginManager.isEditorLanguageSupported(editor)
      util.compileToFile editor

  display: ->
    editor     = atom.workspace.getActiveTextEditor()
    activePane = atom.workspace.getActivePane()

    return unless editor?

    unless pluginManager.isEditorLanguageSupported editor
      return console.warn("Coffee compile: Invalid language")

    atom.workspace.open "coffeecompile://editor/#{editor.id}",
      searchAllPanes: true
      split: "right"
    .then ->
      if atom.config.get('coffee-compile.focusEditorAfterCompile')
        activePane.activate()

  registerProviders: (provider) ->
    pluginManager.register provider
