# Copyright 2016 Skytap Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

should              = require 'should'
sinon               = require 'sinon'
Frame               = require '../../../src/frame'
RenderContextServer = require '../../../src/render_context_server'

describe 'lib/frame.coffee', ->
  describe 'generateHtml', ->
    it 'should call render on its render context and return the instance on which it was called', ->
      class TestFrame extends Frame
        renderContextKlass: RenderContextServer

      frame = new TestFrame().initialize()
      frame.renderContext.render = sinon.stub()

      frame.generateHtml().should.eql(frame)
      frame.renderContext.render.calledOnce.should.be.true()
