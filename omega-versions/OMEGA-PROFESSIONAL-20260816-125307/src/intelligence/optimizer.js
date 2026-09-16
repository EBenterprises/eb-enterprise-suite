export const optimize = (value, transforms = []) =>
  transforms.reduce(
    (current, transform) => transform(current),
    value
  )
