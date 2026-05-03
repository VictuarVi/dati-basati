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

// LIST OF ALLOWED VALUES

#let choices = (
  cardinalities: (
    "(0,1)",
    "(0,n)",
    "(0,N)",
    "(1,0)",
    "(1,1)",
    "(1,n)",
    "(1,N)",
    "(n,0)",
    "(n,1)",
    "(n,n)",
    "(N,0)",
    "(N,1)",
    "(N,N)",
  ),
  subentities: ("(t,e)", "(p,e)", "(p,o)"),
  directions: ("ltr", "rtl"),
  start: ("from-long", "from-short"),
)

// CUSTOM TYPES

#let position-type = z.dictionary(
  optional: true,
  (
    alignment: z.alignment(optional: true),
    dir: z.choice(
      optional: true,
      description: "Drawing direction for attributes",
      name: "direction",
      choices.directions,
    ),
    start: z.choice(
      optional: true,
      description: "Starting drawing direction for attributes",
      name: "start",
      choices.start,
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
  hierarchy: z.choice(
    description: "Subentities hierarchy",
    choices.subentities,
    default: "(t,e)",
  ),
  entity: z.string(),
  subentities: z.array(
    z.string(),
    assertions: (z.assert.length.min(1),),
  ),
))

#let relation-schema = z.dictionary((
  coordinates: z.array(
    optional: true,
    z.either(
      z.integer(),
      z.floating-point(),
    ),
    // assertions: (z.assert.length.equals(2),),
    // post-transform: (self, it) => {
    //   if (it != none and it.len() != 0) {
    //     assert(
    //       it.len() == 2,
    //       message: "Coordinates length must be two.",
    //     )
    //   }
    //   return it
    // },
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
    z.choice(
      description: "Cardinality of the first entity",
      name: "Invalid cardinality",
      choices.cardinalities,
    ),
    default: ("(n,n)", "(n,n)"),
  ),
  intersect: z.boolean(
    optional: true,
    default: false,
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
