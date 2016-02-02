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

extend               = require 'extend'
Inflection           = require 'inflection'
DomDependencyManager = require 'minorjs-dom-dependency-manager'

module.exports = class BaseFrame

  constructor: (options={}) ->
    @viewStructure          = {}
    @populatedViews         = []
    @frameModel           ||= options.frameModel
    @frameModelKlass      ||= options.frameModelKlass
    @frameCollection      ||= options.frameCollection
    @frameCollectionKlass ||= options.frameCollectionKlass
    @pageUrl              ||= options.pageUrl
    @defaultFilters       ||= options.defaultFilters
    @isPage               ||= options.isPage            || false
    @request              ||= options.request           || undefined
    @isNewFrame           ||= options.isNewFrame        || false
    @modelKlasses         ||= options.modelKlasses      || []
    @collectionKlasses    ||= options.collectionKlasses || []
    @viewKlasses          ||= options.viewKlasses       || []
    @payload              ||= options.payload           || {}
    @immutableFilters     ||= options.immutableFilters  || {}
    @domDependencies      ||= options.domDependencies   || {}
    @queryString          ||= @request?.query           || {}
    # TODO: deal with this better
    @sortFields           ||= options.sortFields        || @payload.sortFields

    throw new Error('Undefined renderContextKlass') unless typeof @renderContextKlass is 'function'

    @renderContext = new @renderContextKlass(extend {}, options, frame: @)
    @

  initialize: () ->
    # yields @models and/or @collections
    @setUpResources()
    @generateFrameViewStructure()
    @instantiateViews()
    @setUpMessaging()
    @domDependencyManager = new DomDependencyManager(@viewStructure, @viewInstances)
    @renderContext.initialize()
    @

  mergedFilters: () ->
    extend({}, @defaultFilters, @queryString)

  retrieveFilters: (resourceType) ->
    request          : @request
    defaultFilters   : @defaultFilters
    params           : @mergedFilters(resourceType)
    immutableFilters : @immutableFilters

  setUpResources: () ->
    @models      = {}
    @collections = {}
    @setupFrameModel()
    @setupFrameCollection()
    @setupModels()
    @setupCollections()
    @

  setupFrameModel: () ->
    if @frameModelKlass
      modelType = Inflection.singularize(@frameModelKlass::resource)
      if @isNewFrame
        # TODO: we probably need an ID at least
        modelData    = {}
        modelOptions = {}
      else
        modelData    = @payload[modelType]
        modelOptions = @payload["#{modelType}Options"]
      modelOptions.request = @request if @request

      @models.frameModel = new @frameModelKlass(modelData, modelOptions)
    else if @frameModel
      @models.frameModel = @frameModel
    @

  setupFrameCollection: () ->
    if @frameCollectionKlass
      collectionType = @frameCollectionKlass::resource
      if @isNewFrame
        collectionData    = null
        collectionOptions = @retrieveFilters(collectionType)
      else
        collectionData    = @payload[collectionType]
        collectionOptions = @payload.listOptions
      collectionOptions.request  = @request if @request

      @collections.frameCollection = new @frameCollectionKlass(collectionData, collectionOptions)
    else if @frameCollection
      @collections.frameCollection = @frameCollection
    @

  setupModels: () ->
    for klass in @modelKlasses
      modelType            = Inflection.singularize(klass::resource)
      modelData            = @payload[modelType]
      modelOptions         = @payload["#{modelType}Options"] || {}
      modelOptions.request = @request if @request
      # undefined should be fine here.
      @models[modelType]   = new klass(modelData, modelOptions)
    @

  setupCollections: () ->
    for klass in @collectionKlasses
      collectionType            = klass::resource
      collectionData            = @payload[collectionType]
      collectionOptions         = @payload["#{collectionType}Options"] || {}
      collectionOptions.request = @request if @request
      # undefined should be fine here.
      @collections[collectionType] = new klass(collectionData, collectionOptions)
    @

  getViewAttributes: () ->
    attrs = @renderContext.getViewAttributes()

    # TODO: a little hacky.
    attrs.fields = @sortFields if @sortFields
    # we're going to trust views to sort through this stuff in initialize()
    # and only take what they need
    attrs[if modelType      is 'frameModel'      then 'model'      else modelType]      = modelInstance      for modelType,      modelInstance      of @models
    attrs[if collectionType is 'frameCollection' then 'collection' else collectionType] = collectionInstance for collectionType, collectionInstance of @collections
    attrs

  instantiateViews: () ->
    # Instantiates a flat map lookup with view name as a key, and view instance as value
    attrs = @getViewAttributes()
    @viewInstances = {}
    for klass in @viewKlasses
      @viewInstances[klass::name] = new klass(attrs)
    @

  traverseViewStructure: (views) ->
    # Recursively traverse our known DOM dependencies,
    # recording each view we encounter, so that we
    # don't redundantly store it in @viewStructure
    # when we loop through @viewKlasses later
    for name, value of views
      @populatedViews.push(name) unless @populatedViews.indexOf(name) > -1
      if views[name]
        @traverseViewStructure(views[name])

  generateFrameViewStructure: () ->
    # Generates the structure of views by traversing the hierarchical nodes first,
    # then fills in the top level nodes from viewKlasses that have not yet been traversed.
    @traverseViewStructure(@domDependencies)
    @viewStructure = @domDependencies
    for klass in @viewKlasses
      if @populatedViews.indexOf(klass::name) is -1
        @viewStructure[klass::name] ||= {}
    @

  fetchCollections: () ->
    return unless @collections

    requests = []
    for name, instance of @collections
      requests.push instance.fetch()

    requests

  localsForRender: () ->
    defaultFilters : @defaultFilters
    collections    : @collections
    models         : @models
    # okay if it's undefined
    sortFields     : @sortFields

  generateHtml: () ->
    @renderContext.render()
    @

  setUpMessaging: () ->
    # no op
