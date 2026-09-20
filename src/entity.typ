#import "@preview/cetz:0.5.2"
#import cetz.draw: *
#import "utils.typ": merge-dicts

/// Draw an entity box.
/// -> content
#let _draw-entity-box(
  /// Coordinates.
  /// -> array
  coordinates,
  /// Label of the box.
  /// -> content | str
  label,
  /// Unique name of this entity
  /// -> str
  name,
  /// Whether this entity has weak attributes.
  /// -> bool
  has-weak-entity,
  /// Arguments passed to ```typ #std.rect()```.
  /// -> args
  ..args,
) = {
  get-ctx(ctx => {
    let rect-args = merge-dicts(
      (
        stroke: ctx.theme.stroke.entities,
        fill: ctx.theme.fill.entities,
        radius: ctx.theme.radius.entities,
      ),
      args.named(),
    )
    let label-content = align(center, (ctx.theme.text.entities)(label))
    content(
      coordinates,
      std.rect(
        ..rect-args,
        inset: 1.4em,
        label-content,
      ),
      name: name,
    )
    // simulate double stroke
    if ctx.theme.misc.weak-entities-stroke and has-weak-entity {
      let (width, height) = measure(label-content)
      content(
        coordinates,
        std.rect(
          ..rect-args,
          outset: 1.2em,
          fill: none,
          width: width,
          height: height,
        ),
      )
    }
  })
}
