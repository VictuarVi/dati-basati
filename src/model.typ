#import "@preview/valkyrie:0.2.2" as z

// UTILITY FUNCTIONS

#let string-value(
  values: (),
  default: "",
) = z.string(
  default: default,
  post-transform: (self, it) => {
    assert(
      it != none,
      message: "Value cannot be none.",
    )
    assert(
      it in values,
      message: "Value must be in " + values.join(", ") + ".",
    )
    return it
  },
)

// CUSTOM TYPES

#let position-type = z.dictionary(
  optional: true,
  (
    alignment: z.alignment(optional: true),
    dir: z.string(
      optional: true,
      post-transform: (self, it) => {
        if (it != none) {
          let dir-values = ("ltr", "rtl")
          assert(
            it in dir-values,
            message: "Direction must be either " + dir-values.join(" or ") + ".",
          )
        }
        return it
      },
    ),
    start: z.string(
      optional: true,
      post-transform: (self, it) => {
        if (it != none) {
          let start-values = ("from-short", "from-long")
          assert(
            it in start-values,
            message: "Start must be either " + start-values.join(" or ") + ".",
          )
        }
        return it
      },
    ),
  ),
)

#let single-attr-type = z.either(
  // ((str, str), ...) for composite attr
  z.array(
    z.array(
      z.string(),
      assertions: (z.assert.length.equals(2),),
    ),
    assertions: (z.assert.length.equals(1),),
  ),
  // (str, str, ...)
  z.array(z.string()),
)

#let attributes-type = z.dictionary(
  optional: true,
  (
    north: single-attr-type,
    east: single-attr-type,
    south: single-attr-type,
    west: single-attr-type,
  ),
)

#let misc-type = z.dictionary(
  optional: true,
  (
    weak-entities-stroke: z.boolean(default: false),
    relations-intersection: string-value(values: ("|-", "-|"), default: "|-"),
  ),
)

#let custom-color-type = z.base-type.with(name: "color", types: (color, type(auto), type(none)))
#let custom-stroke-type = z.base-type.with(name: "stroke", types: (stroke, color, type(auto), type(none)))
#let custom-length-type = z.base-type.with(name: "length", types: (length, type(auto), type(none)))

// SCHEMAS

#let entity-schema = z.dictionary((
  coordinates: z.array(
    z.either(
      z.integer(),
      z.floating-point(),
    ),
    assertions: (z.assert.length.equals(2),),
  ),
  name: z.string(default: ""),
  label: z.either(
    z.string(),
    z.content(),
    default: "Entity",
  ),
  attributes: attributes-type,
  attributes-position: z.dictionary(
    optional: true,
    (
      north: position-type,
      east: position-type,
      south: position-type,
      west: position-type,
    ),
  ),
  primary-key: z.either(
    z.string(),
    z.array(
      z.string(),
    ),
    optional: true,
  ),
  weak-entity: z.array(optional: true),
  misc: misc-type,
))

#let subentities-schema = z.dictionary((
  hierarchy: string-value(
    default: "(t,e)",
    values: ("(t,e)", "(p,e)", "(p,o)"),
  ),
  entity: z.string(),
  subentities: z.array(z.string(), default: ("",)),
))

#let relation-schema = z.dictionary((
  coordinates: z.array(
    optional: true,
    z.either(
      z.integer(),
      z.floating-point(),
    ),
    post-transform: (self, it) => {
      if (it != none and it.len() != 0) {
        assert(
          it.len() == 2,
          message: "Coordinates length must be two.",
        )
      }
      return it
    },
  ),
  entities: z.either(
    // ((str, str), (str, str), ...)
    z.array(
      z.array(
        z.string(),
        assertions: (z.assert.length.equals(2),),
      ),
      assertions: (z.assert.length.equals(2),),
    ),
    // (str, str)
    z.array(z.string(), assertions: (z.assert.length.equals(2),)),
  ),
  name: z.string(default: ""),
  label: z.either(
    // (str, str)
    z.array(
      z.string(),
      assertions: (z.assert.length.equals(2),),
    ),
    // (str, cnt, ...)
    z.either(
      z.string(),
      z.content(),
      default: "",
    ),
  ),
  attributes: attributes-type,
  cardinality: z.array(
    z.string(),
    default: ("(n,n)", "(n,n)"),
    post-transform: (self, it) => {
      assert(
        it.len() == 2,
        message: "Length must be equal to 2.",
      )
      let values = (
        "(0,1)",
        "(0,n)",
        "(1,0)",
        "(1,1)",
        "(1,n)",
        "(n,0)",
        "(n,1)",
        "(n,n)",
      )
      assert(
        it.map(e => e in values).filter(e => e == false).len() == 0,
        message: "Values must be in " + values.join(", ") + ".",
      )
      return it
    },
  ),
))

#let settings-schema = z.dictionary(
  optional: true,
  (
    fill: z.dictionary((
      entities: z.color(optional: true),
      relations: z.color(optional: true),
      composite-attributes: custom-color-type(default: auto),
      primary-key: z.color(default: black),
      weak-entity: z.color(optional: true),
      cardinality: z.color(optional: true),
      hierarchy: z.color(optional: true),
    )),
    stroke: z.dictionary((
      entities: custom-stroke-type(default: black),
      relations: custom-stroke-type(default: black),
      attributes: custom-stroke-type(default: black),
      composite-attributes: custom-stroke-type(default: auto),
      primary-key: custom-stroke-type(default: auto),
      weak-entity: custom-stroke-type(default: auto),
      cardinality: custom-stroke-type(default: none),
      hierarchy: custom-stroke-type(default: auto),
      lines: custom-stroke-type(default: auto),
    )),
    radius: z.dictionary((
      entities: z.length(default: 0pt),
      cardinality: z.length(default: 0pt),
      hierarchy: custom-length-type(default: auto),
    )),
    spacing: z.dictionary((
      in-between: z.dictionary(
        (
          x: z.length(default: 1.2em),
          y: z.length(default: 1.2em),
        ),
      ),
      padding: z.length(default: 1.2em),
    )),
    text: z.dictionary((
      entities: z.function(optional: true),
      relations: z.function(optional: true),
      attributes: z.function(optional: true),
      cardinality: z.function(optional: true),
      hierarchy: z.function(optional: true),
    )),
    attributes-position: z.dictionary(
      optional: true,
      (
        north: position-type,
        east: position-type,
        south: position-type,
        west: position-type,
      ),
    ),
    misc: misc-type,
  ),
)
