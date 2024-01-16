export default {
  shouldRender({ category }) {
    return category?.lock;
  },
};
