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

    throw new Error('Undefined renderContextKlass') unless typeof @renderContextKlass is 'function'

    @renderContext = new @renderContextKlass(extend {}, options, frame: @)
    @

  initialize: () ->
    # yields @models and/or @collections
    @setUpResources()
    @instantiateViews()
    @setUpMessaging()
    @domDependencyManager = new DomDependencyManager(@generateFrameViewStructure(), @viewInstances)
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

    # we're going to trust views to sort through this stuff in initialize()
    # and only take what they need
    attrs[if modelType      is 'frameModel'      then 'model'      else modelType]      = modelInstance      for modelType,      modelInstance      of @models
    attrs[if collectionType is 'frameCollection' then 'collection' else collectionType] = collectionInstance for collectionType, collectionInstance of @collections
    attrs

  instantiateViews: () ->
    # Instantiates a flat map lookup with view name as a key, and view instance as value
    standardAttrs = @getViewAttributes()
    @viewInstances = {}
    for klass in @viewKlasses
      @viewInstances[klass::name] = new klass(standardAttrs)

    # supplementalViewKlasses are for views we want to instantiate
    # in an automated way, but which require additional, non-standard
    # attributes AND/OR are only required if a certain condition is met.
    # format for each entry in this array is:
    ## klass     : MyConstructor
    ## attrs     : () -> *optional
    ##   hash of attributes in addition to, or to overwrite, standard attrs
    ## condition : () -> *optional
    ##   must return a boolean
    @supplementalViewKlasses?.length && for viewSpec in @supplementalViewKlasses
     unless viewSpec.condition && viewSpec.condition.call(@) isnt true
        klass = viewSpec.klass
        attrs = extend {}, standardAttrs, viewSpec.attrs?.call(@)
        @viewInstances[attrs.name || klass::name] = new klass(attrs)
    @

  generateFrameViewStructure: () ->
    # deep-clone @domDependencies to avoid messing with the prototype
    viewStructure = extend true, {}, @domDependencies

    traverseViewStructure = (views) =>
      # Recursively traverse our known DOM dependencies,
      # recording each view we encounter, so that we
      # don't redundantly store it in viewStructure
      # when we loop through @viewKlasses later
      for name, value of views
        # @domDependencies allows a special syntax for views that are to be
        # included conditionally. An optional/conditional view will be marked
        # in @domDependencies with a trailing '?'
        # Here, we delete that entry from the viewStructure hash and,
        # if we find that the view has been instantiated, we replace it
        # with a new entry that lacks the trailing '?'
        if name.slice(-1) is '?'
          delete views[name]
          name = name.slice(0, -1)
          views[name] = value if @viewInstances[name]
        @populatedViews.push(name) unless @populatedViews.indexOf(name) > -1
        if views[name]
          traverseViewStructure(views[name])

    # Generates the structure of views by traversing the hierarchical nodes first,
    # then fills in the top level nodes from viewKlasses that have not yet been traversed.
    traverseViewStructure viewStructure
    for name, instance of @viewInstances
      if @populatedViews.indexOf(name) is -1
        viewStructure[name] ||= {}
    viewStructure

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

  generateHtml: () ->
    @renderContext.render()
    @

  setUpMessaging: () ->
    # no op
