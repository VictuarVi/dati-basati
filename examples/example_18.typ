#set page(width: auto, height: auto, margin: 1cm, fill: rgb("#FFE066").lighten(80%))

#import "@preview/cetz:0.4.2"
#import "@preview/dati-basati:0.1.1"

#show: dati-basati.dati-basati.with(
  ..dati-basati.themes.ghibli,
)

#let entities = (
  "user": (
    coordinates: (-6, -12),
    attributes: (
      "north": ("username",),
      "west": ("password", "name", "surname"),
    ),
    primary-key: "username",
    label: "USER",
    name: "user",
  ),
  "supplier": (
    coordinates: (0, -12),
    label: "SUPPLIER",
    name: "supplier",
  ),
  "client": (
    coordinates: (0, -16),
    label: "CLIENT",
    name: "client",
  ),
  "product": (
    coordinates: (0, -2),
    attributes: (
      "east": ("code", "name"),
    ),
    primary-key: ("code",),
    label: "PRODUCT",
    name: "product",
  ),
  "composite": (
    coordinates: (0, -6),
    attributes: (
      "east": ("description", "price_min", "price_max"),
    ),
    label: "composite",
    name: "composite",
  ),
  "simple": (
    coordinates: (8, -6),
    label: "simple",
    name: "simple",
  ),
  "configuration": (
    coordinates: (12.5, -16),
    attributes: (
      "east": ("id", "date"),
    ),
    primary-key: ("id",),
    label: "CONFIGURATION",
    name: "configuration",
  ),
  "sku": (
    coordinates: (8, -12),
    attributes: (
      "south": ("code", "price", "name", "photo_path", "description"),
    ),
    primary-key: ("code",),
    label: "  SKU  ",
    name: "sku",
  ),
)

#let relations = (
  "Definition": (
    // coordinates: (4, 9),
    entities: ("supplier", "composite"),
    label: "defines",
    name: "supplier-composite",
    cardinality: ("(1,n)", "(1,n)"),
  ),
  "creation": (
    // coordinates: (4, 12),
    entities: ("supplier", "sku"),
    label: "creates",
    name: "supplier-sku",
    cardinality: ("(1,n)", "(1,1)"),
  ),
  "Making": (
    // coordinates: (-4, 7),
    entities: ("client", "configuration"),
    label: "makes",
    name: "client-configuration",
    cardinality: ("(1,n)", "(1,1)"),
  ),
  "selection": (
    coordinates: (12.5, -12),
    entities: ("configuration", "sku"),
    label: "selects",
    name: "configuration-sku",
    cardinality: ("(1,n)", "(0,n)"),
  ),
  "Belonging": (
    coordinates: (-4, -2),
    intersect: true,
    entities: ("product", "composite"),
    label: "belongs",
    name: "product-composite",
    cardinality: ("(0,1)", "(1,n)"),
  ),
  "compatibility": (
    // coordinates: (15, 15),
    entities: ("sku", "simple"),
    label: "compatible",
    name: "sku-simple",
    cardinality: ("(1,n)", "(1,n)"),
  ),
)

#dati-basati.er-diagram({
  for entity in entities.values() {
    dati-basati.entity(
      entity.coordinates,
      label: entity.label,
      name: entity.name,
      attributes: entity.at("attributes", default: none),
      attributes-position: entity.at("attributes-position", default: none),
      primary-key: entity.at("primary-key", default: none),
    )
  }

  for relation in relations.values() {
    dati-basati.relation(
      coordinates: relation.at("coordinates", default: none),
      entities: relation.entities,
      label: relation.at("label", default: none),
      name: relation.at("name", default: none),
      cardinality: relation.cardinality,
      intersect: relation.at("intersect", default: false),
    )
  }

  dati-basati.subentities(
    hierarchy: "(t,e)",
    entity: "user",
    subentities: ("supplier", "client"),
  )

  dati-basati.subentities(
    hierarchy: "(t,e)",
    entity: "product",
    subentities: ("composite", "simple"),
  )
})
