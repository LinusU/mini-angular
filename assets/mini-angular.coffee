
ELEMENT_NODE = document.ELEMENT_NODE
ATTRIBUTE_NODE = document.ATTRIBUTE_NODE
TEXT_NODE = document.TEXT_NODE

valueType = (value) ->
  if value is null
    return 'null'
  else if Array.isArray value
    return 'array'
  else
    return typeof value

toString = (value) ->
  switch valueType value
    when 'undefined' then '(undefined)'
    when 'null' then '(null)'
    else value.toString()

class MiniAngular extends EventEmitter
  constructor: (@element) ->
    super
    @store = {}
    constructSetter = (parent, acc, key) =>
      setter = (v) =>
        switch valueType v
          when 'array' then throw new Error('Unsupported type')
          when 'object'
            newObj = {}
            Object.defineProperty parent, key,
              enumerable: true
              configurable: true
              get: => newObj
              set: setter
            Object.keys(v).forEach (k) ->
              constructSetter(newObj, acc + key + '.', k)(v[k])
          else
            Object.defineProperty parent, key,
              enumerable: true
              configurable: true
              get: => @get acc + key
              set: setter
            @set acc + key, v
            @notify acc + key
    constructSetter(@, '', 'root')({})
    @compileElement @element
  get: (acc) ->
    @store[acc]
  getString: (acc) ->
    toString @store[acc]
  set: (acc, value) ->
    switch valueType value
      when 'undefined' then delete @store[acc]
      when 'null' then @store[acc] = null
      when 'number' then @store[acc] = value
      when 'string' then @store[acc] = value
      when 'boolean' then @store[acc] = value
      else throw new Error('Unsupported type')
  notify: (acc) ->
    @emit acc, @get acc
  getTextNode: (acc) ->
    @on acc, (data) -> node.nodeValue = toString data
    node = document.createTextNode @getString acc
  compileAttributeNode: (node) ->
    parts = node.nodeValue.split /\{\{([a-z\.]+)\}\}/g
    if parts.length > 1
      update = (i, data) ->
        parts[i] = toString data
        node.nodeValue = parts.join ''
      parts.forEach (acc, i) =>
        if (i % 2) is 1
          @on 'root.' + acc, (data) -> update i, data
          parts[i] = @getString 'root.' + acc
      node.nodeValue = parts.join ''
  compileTextNode: (node) ->
    parts = node.nodeValue.split /\{\{([a-z\.]+)\}\}/g
    if parts.length > 1
      fragment = document.createDocumentFragment()
      parts.forEach (e, i) =>
        if (i % 2) is 0
          fragment.appendChild document.createTextNode e
        else
          fragment.appendChild @getTextNode 'root.' + e
      node.parentNode.replaceChild fragment, node
  compileNode: (node) ->
    switch node.nodeType
      when ELEMENT_NODE then @compileElement node
      when ATTRIBUTE_NODE then @compileAttributeNode node
      when TEXT_NODE then @compileTextNode node
  compileElement: (el) ->
    if el.hasAttribute 'ng-bind'
      acc = 'root.' + el.getAttribute('ng-bind')
      el.value = @getString acc
      el.addEventListener 'change', (=> @set acc, el.value; @notify acc), false
      el.addEventListener 'keyup', (=> @set acc, el.value; @notify acc), false
      @on acc, (data) ->
        str = toString data
        if el.value isnt str then el.value = str
    for node in el.childNodes then @compileNode node
    for node in el.attributes then @compileNode node

window.MiniAngular = MiniAngular
