noflo = require 'noflo'

unless noflo.isBrowser()
  sinon = require 'sinon' unless sinon
  chai = require 'chai' unless chai
  BrowserifyRequire = require '../components/BrowserifyRequire.coffee'
else
  BrowserifyRequire = require 'noflo-amd/components/BrowserifyRequire.js'


describe 'BrowserifyRequire', ->

  c = null

  beforeEach ->
    c = BrowserifyRequire.getComponent()

  describe 'inPorts', ->

    it 'should contain "name"', ->
      expect(c.inPorts.name).to.be.an 'object'

    it 'should contain "component"', ->
      expect(c.inPorts.component).to.be.an 'object'

  describe 'outPorts', ->

    it 'should contain "module"', ->
      expect(c.outPorts.module).to.be.an 'object'

    it 'should contain "error"', ->
      expect(c.outPorts.error).to.be.an 'object'

  describe 'data flow', ->

    nameIn = null
    componentIn = null
    moduleOut = null
    errorOut = null
    sandbox = null
    component = null

    beforeEach ->
      # Create mock sockets.
      nameIn = noflo.internalSocket.createSocket()
      componentIn = noflo.internalSocket.createSocket()
      moduleOut = noflo.internalSocket.createSocket()
      errorOut = noflo.internalSocket.createSocket()

      # Attach mocks on inPort.
      c.inPorts.name.attach nameIn
      c.inPorts.component.attach componentIn

      # Attach mocks on outPorts.
      c.outPorts.module.attach moduleOut

      # Setup spies.
      sandbox = sinon.sandbox.create()
      component = sandbox.spy()
      window.bRequire = sandbox.stub().returns component

    afterEach ->
      sandbox.restore()
      delete window.bRequire

    it 'should allow "name" to be optional', (done) ->
      moduleOut.on 'data', (data) ->
        done()

      componentIn.send 'components/MyComponent'

    it 'should have configurable require function', (done) ->
      window.cRequire = sandbox.spy()

      moduleOut.on 'data', (data) ->
        expect(window.cRequire.called).to.be.true
        expect(window.cRequire.firstCall.args).to.deep.equal [
          'components/MyComponent']
        delete window.cRequire
        done()

      nameIn.send 'cRequire'
      componentIn.send 'components/MyComponent'

    it 'should require the component', (done) ->
      moduleOut.on 'data', (data) ->
        expect(window.bRequire.called).to.be.true
        expect(window.bRequire.firstCall.args).to.deep.equal [
          'components/MyComponent']
        done()

      componentIn.send 'components/MyComponent'

    it 'should send the module', (done) ->
      moduleOut.on 'data', (data) ->
        expect(data).to.eql component
        done()

      componentIn.send 'components/MyComponent'

    it 'should disconnect "module" after sending data', (done) ->
      moduleOut.on 'disconnect', ->
        done()

      componentIn.send 'components/MyComponent'

    describe 'when require function cannot be found', ->

      beforeEach ->
        nameIn.send 'does-not-exist'

      it 'should throw when error port is not connected', ->
        throws = () ->
          componentIn.send 'components/MyComponent'

        expect(throws).to.throw Error

      it 'should not throw when error port is connected', ->
        c.outPorts.error.attach errorOut

        throws = () ->
          componentIn.send 'components/MyComponent'

        expect(throws).to.not.throw Error

      it 'should send the error', (done) ->
        c.outPorts.error.attach errorOut

        errorOut.on 'data', (data) ->
          expect(data.message).to.eql '\"does-not-exist\" is not a function.'
          done()

        componentIn.send 'components/MyComponent'

      it 'should disconnect the error port', (done) ->
        c.outPorts.error.attach errorOut

        errorOut.on 'disconnect', ->
          done()

        componentIn.send 'components/MyComponent'

    describe 'when module constructor cannot be found', ->

      beforeEach ->
        window.bRequire.throws new TypeError

      it 'should throw when error port is not connected', ->
        throws = () ->
          componentIn.send 'does-not-exist'

        expect(throws).to.throw TypeError

      it 'should not throw when error port is connected', ->
        c.outPorts.error.attach errorOut

        throws = () ->
          componentIn.send 'does-not-exist'

        expect(throws).to.not.throw Error

      it 'should send the error', (done) ->
        c.outPorts.error.attach errorOut

        errorOut.on 'data', (data) ->
          expect(data.message).to.eql '\"does-not-exist\" is not a module.'
          done()

        componentIn.send 'does-not-exist'

      it 'should disconnect the error port', (done) ->
        c.outPorts.error.attach errorOut

        errorOut.on 'disconnect', ->
          done()

        componentIn.send 'does-not-exist'

