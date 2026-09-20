#import "@preview/cetz:0.5.2"
#import cetz.draw: *
#import "entity.typ": *
#import "attributes.typ": *
#import "weak-entity.typ": *
#import "cardinality.typ": *
#import "custom-marks.typ"
#import "utils.typ": *
#import "themes.typ": themes
#import "model.typ": *

#let default-theme = (
  fill: (
    entities: none,
    relations: auto, // auto inherits entities
    primary-key: black,
    weak-entity: auto, // auto inherits primary-key
    cardinality: auto, // auto = page fill
    hierarchy: auto, // auto inherits cardinality
    composite-attributes: auto, // auto inherits entities
  ),
  stroke: (
    entities: black,
    relations: black, // auto inherits entities
    lines: auto, // auto inherits entities
    attributes: black,
    composite-attributes: auto, // auto inherits attributes
    primary-key: auto, // auto inherits attributes
    weak-entity: auto, // auto inherits primary-key
    cardinality: none,
    hierarchy: auto, // auto inherits cardinality
  ),
  radius: (
    entities: 0pt,
    cardinality: 0pt,
    hierarchy: auto, // auto inherits cardinality
  ),
  spacing: (
    in-between: (x: 1.2em, y: 1.2em), // spacing between attributes
    padding: 1.2em, // distance from the entity
  ),
  text: (
    entities: l => {
      set par(leading: 0.35em)
      text(
        top-edge: "bounds",
        size: 1.5em,
        weight: "bold",
        smallcaps(lower(l)),
      )
    },
    relations: l => l,
    relations-outside: auto, // auto inherits relations
    attributes: l => l,
    cardinality: l => text(top-edge: "bounds", bottom-edge: "bounds", l),
    hierarchy: auto,
  ),
  attributes-position: (
    "north": (
      alignment: left,
      dir: "ltr",
      start: "from-short",
    ),
    "east": (
      alignment: center,
      dir: "ltr",
    ),
    "south": (
      alignment: right,
      dir: "rtl",
      start: "from-short",
    ),
    "west": (
      alignment: center,
      dir: "rtl",
    ),
  ),
  misc: (
    weak-entities-stroke: false, // double stroke weak entities
    relations-intersection: "|-",
  ),
)

#let _default-theme-state = state(
  "__default-theme-state",
  default-theme,
)

/// Default global theme.
/// -> dictionary
#let dati-basati(
  /// Global theme for ER diagrams.
  /// -> dictionary
  theme: (:),
  /// The fill of each element. Deprecated: use `theme`.
  /// -> dictionary
  fill: (:),
  /// The stroke of each element. . Deprecated: use `theme`.
  /// -> dictionary
  stroke: (:),
  /// The radius of entities, cardinality and hierarchy. . Deprecated: use `theme`.
  /// -> dictionary
  radius: (:),
  /// The spacing of attributes. . Deprecated: use `theme`.
  /// -> dictionary
  spacing: (:),
  /// Text formatting of each element. . Deprecated: use `theme`.
  /// -> dictionary
  text: (:),
  /// The position and direction of attributes. . Deprecated: use `theme`.
  /// -> dictionary
  attributes-position: (:),
  /// Miscellanous options. . Deprecated: use `theme`.
  /// -> dictionary
  misc: (:),
  body,
) = {
  _ = z.parse(
    (
      fill: fill,
      stroke: stroke,
      radius: radius,
      spacing: spacing,
      text: text,
      attributes-position: attributes-position,
      misc: misc,
    ),
    theme-schema,
  )

  // retrocompatibility
  if (theme == (:)) {
    theme = (
      fill: fill,
      stroke: stroke,
      radius: radius,
      spacing: spacing,
      text: text,
      attributes-position: attributes-position,
      misc: misc,
    )
  }

  _default-theme-state.update(s => {
    let old = s

    if (old == none) { return }

    let old = merge-dicts(default-theme, theme)

    return old
  })

  body
}

/// Draw an Entity-Relation Diagram. This is the function that wraps all the
/// diagrams.
/// -> content
#let er-diagram(
  /// The theme of this diagram.
  /// -> dictionary
  theme: (:),
  /// Arguments directly passed to ```typ #cetz.canvas()```.
  /// -> dictionary
  ..args,
  /// Body of the diagram.
  /// -> content
  body,
) = context {
  let local-theme = merge-dicts(_default-theme-state.get(), theme)
  context {
    cetz.canvas(
      ..args,
      {
        set-ctx(ctx => ctx + (theme: local-theme))

        custom-marks.subentity-mark
        custom-marks.righetta
        custom-marks.empty-circle

        get-ctx(ctx => {
          custom-marks.filled-circle-mpk(fill: ctx.theme.fill.primary-key)
          custom-marks.filled-circle-pk(fill: ctx.theme.fill.primary-key)
        })

        body
      },
    )
  }
}

/// Draw an entity.
/// -> content
#let entity(
  /// Coordinates of the entity.
  /// -> array
  coordinates,
  /// Unique name of the entity.
  /// -> str
  name: "",
  /// Label for the entity (e.g. Person, Book, Employee...).
  /// -> str | content
  label: "Entity",
  /// Attributes of the entity (e.g. id, name, surname, address...).
  /// -> dictionary
  attributes: (:),
  /// Fine tune positioning of attributes.
  /// -> dictionary
  attributes-position: (:),
  /// Primary key(s).
  /// -> str | array
  primary-key: none,
  /// Whether this entity is weak and the corresponding attribute. The format is as follows:
  /// - SQL mirror: `(attribute, strong entity, direction)`
  /// - With cardinal points: `(cardinal pt, cardinal pt, direction)`
  /// They can be mixed.
  /// -> array
  weak-entity: none,
  /// Miscellanous options:
  /// - weak-entity-intersection
  /// -> dictionary
  misc: none,
  /// Arguments passed to ```typ #std.rect()```.
  /// -> args
  ..args,
) = {
  _ = z.parse(
    (
      coordinates: coordinates,
      name: name,
      label: label,
      attributes: attributes,
      attributes-position: attributes-position,
      primary-key: primary-key,
      weak-entity: weak-entity,
      misc: misc,
    ),
    entity-schema,
  )

  let is-multiple-pk = type(primary-key) == array and primary-key.len() > 1
  let is-single-array = type(primary-key) == array and primary-key.len() == 1

  _draw-entity-box(coordinates, label, name, weak-entity != none, ..args)

  // draw attributes and single primary key
  if attributes != none {
    get-ctx(ctx => {
      let merged-attributes-position = merge-dicts(
        ctx.theme.attributes-position,
        attributes-position,
      )

      let is-there-an-array(x) = x.filter(e => type(e) == array).len() > 0

      for (side, attr) in attributes {
        if is-there-an-array(attr) {
          _draw-composite-attribute(
            name + "." + side,
            attr.at(0),
            position: side,
            in-between: ctx.theme.spacing.in-between,
            padding: ctx.theme.spacing.padding,
          )
          continue
        }

        let starting-coordinate = get-aligned-coordinate(
          name,
          side,
          merged-attributes-position.at(side).alignment,
          ctx.theme.spacing.in-between,
          1,
        )

        let pk = if is-single-array { primary-key.at(0) } else if not is-multiple-pk { primary-key }

        let draw-mode = if ("north", "south").contains(side) { merged-attributes-position.at(side).start }

        _draw-attributes(
          starting-coordinate,
          entity: name,
          attributes: attr,
          position: side,
          primary-key: pk,
          dir: merged-attributes-position.at(side).dir,
          drawing-mode: draw-mode,
          centered: merged-attributes-position.at(side).alignment == center,
          in-between: ctx.theme.spacing.in-between,
          padding: ctx.theme.spacing.padding,
        )
      }
    })
  }

  if is-multiple-pk {
    get-ctx(ctx => {
      let intersection = if ("north", "south").contains(find-side(primary-key.first(), attributes)) { "-|" } else {
        "|-"
      }

      let marks = if ("north", "south").contains(find-side(primary-key.first(), attributes)) {
        (end: "righetta", start: "filled-circle-mpk")
      } else { (start: "righetta", end: "filled-circle-mpk") }

      line(
        name + "-" + primary-key.first() + ".mid",
        ((), intersection, name + "-" + primary-key.last()),
        mark: marks,
        stroke: handle-auto(
          ctx.theme.stroke.primary-key,
          ctx.theme.stroke.attributes,
        ),
      )
    })
  }

  if weak-entity != none {
    get-ctx(ctx => {
      let old-api = cardinal-points.contains(weak-entity.at(1))
      let direction = weak-entity.at(2, default: "CW")
      if old-api {
        _draw-we-path(
          name,
          (weak-entity.at(0), weak-entity.at(1), direction),
          attributes,
          ctx.theme.spacing.padding,
        )
        return
      }

      let normal = find-side(weak-entity.at(0), attributes) != false
      let strong-entity-position = get-rel-position-diagonal(name, weak-entity.at(1), ctx)

      if normal {
        if strong-entity-position.len() != 1 {
          if misc != none and misc.at("weak-entity-intersection", default: none) != none {
            anchor(
              name + "-" + weak-entity.at(1),
              (name, misc.weak-entity-intersection, weak-entity.at(1)),
            )
          }
          get-ctx(ctx => {
            add-intersect-anchor(
              _draw-we-path(
                name,
                strong-entity-position,
                attributes,
                ctx.theme.spacing.padding,
              ),
              if misc != none and misc.at("weak-entity-intersection", default: none) != none {
                (name, name + "-" + weak-entity.at(1))
              } else {
                (name, weak-entity.at(1))
              },
            )
            utils.draw-anchors(name, ctx.theme.spacing.padding / 2)
          })
          get-ctx(ctx => {
            let final-side = utils.get-diagonal-side("intersection.0", name, ctx)
            let intersection = cetz.coordinate.resolve(ctx, "intersection.0").at(1).slice(0, 2)
            // circle("intersection.0", radius: 0.05, fill: red)
            _draw-we-path(
              name,
              (weak-entity.at(0), final-side, direction),
              attributes,
              ctx.theme.spacing.padding,
              intersection: intersection,
            )
          })
        } else {
          _draw-we-path(
            name,
            (weak-entity.at(0), strong-entity-position.first(), direction),
            attributes,
            ctx.theme.spacing.padding,
          )
        }
      } else {
        let other-strong-entity-position = get-rel-position-diagonal(name, weak-entity.at(0), ctx)
        if strong-entity-position.len() != 1 and other-strong-entity-position.len() != 1 {
          panic("Not implemented yet. Line up strong entities on the axis.")
        } else {
          _draw-we-path(
            name,
            (
              other-strong-entity-position.first(),
              strong-entity-position.first(),
              direction,
            ),
            attributes,
            ctx.theme.spacing.padding,
          )
        }
      }
    })
  }
}

/// Connect subentities to the superentity.
/// -> content
#let subentities(
  /// The hierarchy of the subentities:
  /// - (t,e) = (total, exclusive)
  /// - (p,e) = (partial, exclusive)
  /// - (p,o) = (partial, overlapping)
  /// -> "(t,e)" | "(p,e)" | "(p,o)"
  hierarchy: "(t,e)",
  /// The superentity, the one to which the subentities will connect.
  /// -> str
  entity: "",
  /// The subentities. Can be just one.
  /// -> array
  subentities: ("",),
) = {
  _ = z.parse(
    (
      hierarchy: hierarchy,
      entity: entity,
      subentities: subentities,
    ),
    subentities-schema,
  )

  let entity-position-dict = (
    // (to get meeting point, lines from subentities)
    "north": ("-|", "|-"),
    "east": ("|-", "-|"),
    "south": ("-|", "|-"),
    "west": ("|-", "-|"),
  )

  get-ctx(ctx => {
    let entity-position = utils.get-rel-entities(entity, subentities, ctx)
    let opposite-cardinal = get-opp-cardinal(entity-position)
    let intersection-array = entity-position-dict.at(entity-position)

    _draw-cardinality-box(
      entity + "." + opposite-cardinal,
      label: hierarchy,
      name: "hierarchy-box",
      hierarchy: true,
    )

    // hide({
    //   line(
    //     (
    //       subentities.at(0) + "." + entity-position,
    //       intersection-array.at(0),
    //       "hierarchy-box" + "." + opposite-cardinal,
    //     ),
    //     "hierarchy-box" + "." + opposite-cardinal,
    //     name: "tmp",
    //   )
    // })
    // let meeting-point = "tmp.mid"
    anchor(
      "tmp",
      (
        (
          subentities.at(0) + "." + entity-position,
          intersection-array.at(0),
          "hierarchy-box" + "." + opposite-cardinal,
        ),
        50%,
        "hierarchy-box" + "." + opposite-cardinal,
      ),
    )

    let meeting-point = "tmp"

    // "shared" line between subentities
    line(
      (subentities.first(), intersection-array.at(1), meeting-point),
      meeting-point,
    )
    line(
      meeting-point,
      (subentities.last(), intersection-array.at(1), meeting-point),
    )
    for subentity in subentities {
      line(
        subentity,
        (
          subentity,
          intersection-array.at(1),
          meeting-point,
        ),
        // stroke: ctx.theme.stroke.subentities,
      )
    }

    // hide(line(meeting-point, entity, name: "cardinality-position"))
    line(
      meeting-point,
      "hierarchy-box",
      mark: (end: "subentity-mark"),
      name: "line-subentities",
      // stroke: ctx.theme.stroke.subentities,
    )
  })
}

/// Draw a relation between (sub)entities.
/// -> content
#let relation(
  /// The specific coordinates of this relation. If left empty, they will the middle point
  /// between the two entities.
  /// -> array
  coordinates: none,
  /// Entities that are tied by this relation.
  /// -> array
  entities: (),
  /// Unique name of relation.
  /// -> str
  name: "",
  /// Label for the relation (e.g. "occupies", "relates", "is part of"...).
  /// -> str
  label: "",
  /// Attributes of the relation (e.g. id, name, surname, address...).
  /// -> dictionary
  attributes: (:),
  /// Cardinality of the given relation:
  /// -> array
  cardinality: (),
  /// Whether to intersect the lines connecting relations instead of a direct
  /// connection.
  /// -> bool
  intersect: false,
  /// Arguments passed to ```typ #std.rect()```.
  /// -> args
  ..args,
) = {
  _ = z.parse(
    (
      coordinates: coordinates,
      entities: entities,
      name: name,
      label: label,
      attributes: attributes,
      cardinality: cardinality,
      intersect: intersect,
    ),
    relation-schema,
  )

  if coordinates == none {
    hide({ line(..entities, name: "tmp") })
    coordinates = "tmp.mid"
  }

  let is-entities-array = (
    type(entities.at(0)) == array,
    type(entities.at(1)) == array,
  )

  let is-same-entity = (
    entities.at(0) == entities.at(1)
      or (
        is-entities-array.at(0) and is-entities-array.at(1) and entities.at(0).at(0) == entities.at(1).at(0) // first element of each array
      )
      or (
        is-entities-array.at(0) and entities.at(0).at(0) == entities.at(0) // first element of first array
      )
      or (
        is-entities-array.at(1) == array and entities.at(0) == entities.at(1).at(0) // first element of second array
      )
  )

  let is-array = type(label) == array

  get-ctx(ctx => {
    let polygon-args = merge-dicts(
      (
        fill: handle-auto(
          ctx.theme.fill.relations,
          ctx.theme.fill.entities,
        ),
        stroke: handle-auto(
          ctx.theme.stroke.relations,
          ctx.theme.stroke.entities,
        ),
      ),
      args.named(),
    )

    polygon(
      coordinates,
      4, // sides
      radius: if not is-array and label != none {
        measure(label).width * 0.5 + measure(label).height
      } else {
        0.5
      },
      name: name,
      ..polygon-args,
    )

    // print the label
    let label-args = (
      padding: 1.7em,
    )
    let label-str = ""
    if is-array {
      label-args.insert("anchor", label.at(1))
      label-str = handle-auto(
        ctx.theme.text.relations-outside,
        ctx.theme.text.relations,
      )(label.at(0))
    } else {
      label-str = align(center, (ctx.theme.text.relations)(label))
    }
    content(
      (),
      ..label-args,
      label-str,
    )

    set-style(
      line: (
        stroke: handle-auto(
          ctx.theme.stroke.lines,
          ctx.theme.stroke.entities,
        ),
      ),
    )
  })

  if not is-same-entity {
    get-ctx(ctx => {
      let entity-position = utils.get-rel-entities(name, entities, ctx)
      for i in range(0, entities.len()) {
        let coordinate-start = if is-array { label.at(0) } else { label }
        let arr = (entities.at(i),)
        if (intersect and not is-same-axis(entities.at(i), name, ctx)) {
          let intersecton-symbol = "-|"
          if (entity-position in ("north", "south")) {
            intersecton-symbol = "|-"
          }
          arr.push((entities.at(i), intersecton-symbol, name))
        }
        arr.push(name)
        line(
          ..arr,
          name: coordinate-start + "-" + entities.at(i),
        )
        _draw-cardinality-box(
          coordinate-start + "-" + entities.at(i) + ".start",
          label: cardinality.at(i),
        )
      }
    })
  } else {
    let from-entity = if is-entities-array.at(0) {
      (
        entities.at(0).at(0) + "." + entities.at(0).at(1),
        ((), "|-", name),
      )
    } else {
      (
        entities.at(0) + ".north",
        (rel: (0, 1)),
        ((), "-|", name),
      )
    }
    let to-entity = (
      if is-entities-array.at(1) {
        (
          entities.at(1).at(0) + "." + entities.at(1).at(1),
        )
      } else {
        (
          entities.at(1) + ".south",
          (rel: (0, -1)),
        )
      }
        + (((), "-|", name),)
    )
    line(
      ..from-entity,
      name,
      name: name + "-from-entity",
    )
    line(
      ..to-entity,
      name,
      name: name + "-to-entity",
    )
    _draw-cardinality-box(
      name + "-from-entity" + ".start",
      label: cardinality.at(0),
    )
    _draw-cardinality-box(
      name + "-to-entity" + ".start",
      label: cardinality.at(1),
    )
  }

  if attributes != none {
    for (side, attr) in attributes {
      _draw-attributes(
        name + "." + side,
        entity: name,
        attributes: attr,
        position: side,
      )
    }
  }
}
