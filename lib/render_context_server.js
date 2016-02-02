/**
 * Copyright 2016 Skytap Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/
(function() {
  var RenderContext, RenderContextServer,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  RenderContext = require('./render_context');

  module.exports = RenderContextServer = (function(superClass) {
    extend(RenderContextServer, superClass);

    function RenderContextServer() {
      return RenderContextServer.__super__.constructor.apply(this, arguments);
    }

    RenderContextServer.prototype.render = function() {
      var i, instance, len, ref, viewName;
      ref = this.frame.domDependencyManager.views;
      for (i = 0, len = ref.length; i < len; i++) {
        viewName = ref[i];
        instance = this.frame.viewInstances[viewName];
        if (!instance) {
          throw new Error(viewName + " included but instance of " + viewName + " was undefined");
        }
        instance.refreshEl().render();
      }
      return this;
    };

    return RenderContextServer;

  })(RenderContext);

}).call(this);
