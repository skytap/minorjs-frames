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
  var Backbone, RenderContext, RenderContextBrowser,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Backbone = require('backbone');

  RenderContext = require('./render_context');

  module.exports = RenderContextBrowser = (function(superClass) {
    extend(RenderContextBrowser, superClass);

    function RenderContextBrowser() {
      return RenderContextBrowser.__super__.constructor.apply(this, arguments);
    }

    RenderContextBrowser.prototype.initialize = function() {
      if (!this.frame.isNewFrame) {
        this.postRenderAll();
      }
      return this;
    };

    RenderContextBrowser.prototype.postRenderAll = function() {
      var i, len, ref, viewName;
      ref = this.frame.domDependencyManager.topLevelViews;
      for (i = 0, len = ref.length; i < len; i++) {
        viewName = ref[i];
        if (!this.frame.viewInstances[viewName]) {
          throw new Error(viewName + " included but instance of " + viewName + " was undefined");
        }
        this.frame.viewInstances[viewName].postRender();
      }
      return this;
    };

    RenderContextBrowser.prototype.render = function() {
      var i, len, ref, viewName;
      ref = this.frame.domDependencyManager.views;
      for (i = 0, len = ref.length; i < len; i++) {
        viewName = ref[i];
        this.frame.viewInstances[viewName].refreshEl().render();
      }
      return this;
    };

    return RenderContextBrowser;

  })(RenderContext);

}).call(this);
