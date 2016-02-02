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

Backbone        = require 'backbone'
RenderContext   = require './render_context'

module.exports = class RenderContextBrowser extends RenderContext

  initialize: () ->
    @postRenderAll() unless @frame.isNewFrame
    @

  postRenderAll: () ->
    # Only postrender top level views, which have their rendering functions wrapped to bubble down their descendent views.
    # This avoids double rendering.
    for viewName in @frame.domDependencyManager.topLevelViews
      unless @frame.viewInstances[viewName]
        throw new Error "#{viewName} included but instance of #{viewName} was undefined"
      @frame.viewInstances[viewName].postRender()
    @

  render: () ->
    for viewName in @frame.domDependencyManager.views
      @frame.viewInstances[viewName].refreshEl().render()
    @
