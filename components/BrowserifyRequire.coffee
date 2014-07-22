noflo = require 'noflo'

exports.getComponent = ->
  handleError = (err) ->
    if c.outPorts.error.isAttached()
      c.outPorts.error.send err
      c.outPorts.error.disconnect()
    else
      throw err

  requireName = 'bRequire'

  c = new noflo.Component
  c.description = 'Allows requiring of browserify modules.'

  # Declare inPorts.
  c.inPorts.add 'name',
    datatype: 'string'
    description: "Function name for browserify's require. Defaults to
      \"bRequire\"."

  c.inPorts.add 'component',
    datatype: 'string'
    description: "Name of the component to be required."

  # Declare outPorts.
  c.outPorts.add 'module',
    datatype: 'all'
    description: 'The module being required.'
    required: false

  c.outPorts.add 'error',
    datatype: 'object'
    description: 'Any eror thrown during module requireing.'
    required: false

  # Event handling.
  c.inPorts.name.on 'data', (name) ->
    requireName = name

  c.inPorts.component.on 'data', (componentPath) ->
    requireFunc = window[requireName]

    unless requireFunc instanceof Function
      err = new TypeError "\"#{requireName}\" is not a function."
      return handleError err

    try
      module = requireFunc.call null, componentPath
    catch e
      err = new TypeError "\"#{componentPath}\" is not a module."
      return handleError err

    c.outPorts.module.send module
    c.outPorts.module.disconnect()

  return c
