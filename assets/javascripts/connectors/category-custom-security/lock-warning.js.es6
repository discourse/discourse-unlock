export default {
  shouldRender({ category }, _) {
    return category?.lock;
  }
}
