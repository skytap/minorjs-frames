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

RenderContext = require './render_context'

module.exports = class RenderContextServer extends RenderContext

  render: () ->
    for viewName in @frame.domDependencyManager.views
      instance = @frame.viewInstances[viewName]
      unless instance
        throw new Error("#{viewName} included but instance of #{viewName} was undefined")
      instance.refreshEl().render()
    @
