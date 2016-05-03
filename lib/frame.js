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
  var BaseFrame, DomDependencyManager, Inflection, extend;

  extend = require('extend');

  Inflection = require('inflection');

  DomDependencyManager = require('minorjs-dom-dependency-manager');

  module.exports = BaseFrame = (function() {
    function BaseFrame(options) {
      var ref;
      if (options == null) {
        options = {};
      }
      this.viewStructure = {};
      this.populatedViews = [];
      this.frameModel || (this.frameModel = options.frameModel);
      this.frameModelKlass || (this.frameModelKlass = options.frameModelKlass);
      this.frameCollection || (this.frameCollection = options.frameCollection);
      this.frameCollectionKlass || (this.frameCollectionKlass = options.frameCollectionKlass);
      this.pageUrl || (this.pageUrl = options.pageUrl);
      this.defaultFilters || (this.defaultFilters = options.defaultFilters);
      this.isPage || (this.isPage = options.isPage || false);
      this.request || (this.request = options.request || void 0);
      this.isNewFrame || (this.isNewFrame = options.isNewFrame || false);
      this.modelKlasses || (this.modelKlasses = options.modelKlasses || []);
      this.collectionKlasses || (this.collectionKlasses = options.collectionKlasses || []);
      this.viewKlasses || (this.viewKlasses = options.viewKlasses || []);
      this.payload || (this.payload = options.payload || {});
      this.immutableFilters || (this.immutableFilters = options.immutableFilters || {});
      this.domDependencies || (this.domDependencies = options.domDependencies || {});
      this.queryString || (this.queryString = ((ref = this.request) != null ? ref.query : void 0) || {});
      if (typeof this.renderContextKlass !== 'function') {
        throw new Error('Undefined renderContextKlass');
      }
      this.renderContext = new this.renderContextKlass(extend({}, options, {
        frame: this
      }));
      this;
    }

    BaseFrame.prototype.initialize = function() {
      this.setUpResources();
      this.generateFrameViewStructure();
      this.instantiateViews();
      this.setUpMessaging();
      this.domDependencyManager = new DomDependencyManager(this.viewStructure, this.viewInstances);
      this.renderContext.initialize();
      return this;
    };

    BaseFrame.prototype.mergedFilters = function() {
      return extend({}, this.defaultFilters, this.queryString);
    };

    BaseFrame.prototype.retrieveFilters = function(resourceType) {
      return {
        request: this.request,
        defaultFilters: this.defaultFilters,
        params: this.mergedFilters(resourceType),
        immutableFilters: this.immutableFilters
      };
    };

    BaseFrame.prototype.setUpResources = function() {
      this.models = {};
      this.collections = {};
      this.setupFrameModel();
      this.setupFrameCollection();
      this.setupModels();
      this.setupCollections();
      return this;
    };

    BaseFrame.prototype.setupFrameModel = function() {
      var modelData, modelOptions, modelType;
      if (this.frameModelKlass) {
        modelType = Inflection.singularize(this.frameModelKlass.prototype.resource);
        if (this.isNewFrame) {
          modelData = {};
          modelOptions = {};
        } else {
          modelData = this.payload[modelType];
          modelOptions = this.payload[modelType + "Options"];
        }
        if (this.request) {
          modelOptions.request = this.request;
        }
        this.models.frameModel = new this.frameModelKlass(modelData, modelOptions);
      } else if (this.frameModel) {
        this.models.frameModel = this.frameModel;
      }
      return this;
    };

    BaseFrame.prototype.setupFrameCollection = function() {
      var collectionData, collectionOptions, collectionType;
      if (this.frameCollectionKlass) {
        collectionType = this.frameCollectionKlass.prototype.resource;
        if (this.isNewFrame) {
          collectionData = null;
          collectionOptions = this.retrieveFilters(collectionType);
        } else {
          collectionData = this.payload[collectionType];
          collectionOptions = this.payload.listOptions;
        }
        if (this.request) {
          collectionOptions.request = this.request;
        }
        this.collections.frameCollection = new this.frameCollectionKlass(collectionData, collectionOptions);
      } else if (this.frameCollection) {
        this.collections.frameCollection = this.frameCollection;
      }
      return this;
    };

    BaseFrame.prototype.setupModels = function() {
      var i, klass, len, modelData, modelOptions, modelType, ref;
      ref = this.modelKlasses;
      for (i = 0, len = ref.length; i < len; i++) {
        klass = ref[i];
        modelType = Inflection.singularize(klass.prototype.resource);
        modelData = this.payload[modelType];
        modelOptions = this.payload[modelType + "Options"] || {};
        if (this.request) {
          modelOptions.request = this.request;
        }
        this.models[modelType] = new klass(modelData, modelOptions);
      }
      return this;
    };

    BaseFrame.prototype.setupCollections = function() {
      var collectionData, collectionOptions, collectionType, i, klass, len, ref;
      ref = this.collectionKlasses;
      for (i = 0, len = ref.length; i < len; i++) {
        klass = ref[i];
        collectionType = klass.prototype.resource;
        collectionData = this.payload[collectionType];
        collectionOptions = this.payload[collectionType + "Options"] || {};
        if (this.request) {
          collectionOptions.request = this.request;
        }
        this.collections[collectionType] = new klass(collectionData, collectionOptions);
      }
      return this;
    };

    BaseFrame.prototype.getViewAttributes = function() {
      var attrs, collectionInstance, collectionType, modelInstance, modelType, ref, ref1;
      attrs = this.renderContext.getViewAttributes();
      ref = this.models;
      for (modelType in ref) {
        modelInstance = ref[modelType];
        attrs[modelType === 'frameModel' ? 'model' : modelType] = modelInstance;
      }
      ref1 = this.collections;
      for (collectionType in ref1) {
        collectionInstance = ref1[collectionType];
        attrs[collectionType === 'frameCollection' ? 'collection' : collectionType] = collectionInstance;
      }
      return attrs;
    };

    BaseFrame.prototype.instantiateViews = function() {
      var attrs, i, klass, len, ref;
      attrs = this.getViewAttributes();
      this.viewInstances = {};
      ref = this.viewKlasses;
      for (i = 0, len = ref.length; i < len; i++) {
        klass = ref[i];
        this.viewInstances[klass.prototype.name] = new klass(attrs);
      }
      return this;
    };

    BaseFrame.prototype.traverseViewStructure = function(views) {
      var name, results, value;
      results = [];
      for (name in views) {
        value = views[name];
        if (!(this.populatedViews.indexOf(name) > -1)) {
          this.populatedViews.push(name);
        }
        if (views[name]) {
          results.push(this.traverseViewStructure(views[name]));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    BaseFrame.prototype.generateFrameViewStructure = function() {
      var base, i, klass, len, name1, ref;
      this.traverseViewStructure(this.domDependencies);
      this.viewStructure = this.domDependencies;
      ref = this.viewKlasses;
      for (i = 0, len = ref.length; i < len; i++) {
        klass = ref[i];
        if (this.populatedViews.indexOf(klass.prototype.name) === -1) {
          (base = this.viewStructure)[name1 = klass.prototype.name] || (base[name1] = {});
        }
      }
      return this;
    };

    BaseFrame.prototype.fetchCollections = function() {
      var instance, name, ref, requests;
      if (!this.collections) {
        return;
      }
      requests = [];
      ref = this.collections;
      for (name in ref) {
        instance = ref[name];
        requests.push(instance.fetch());
      }
      return requests;
    };

    BaseFrame.prototype.localsForRender = function() {
      return {
        defaultFilters: this.defaultFilters,
        collections: this.collections,
        models: this.models
      };
    };

    BaseFrame.prototype.generateHtml = function() {
      this.renderContext.render();
      return this;
    };

    BaseFrame.prototype.setUpMessaging = function() {};

    return BaseFrame;

  })();

}).call(this);
