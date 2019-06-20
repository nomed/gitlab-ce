<script>
export default {
  name: 'RegistrySvgMessage',
  props: {
    id: {
      type: String,
      required: true,
    },
    svgPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div :id="id" class="container-message">
    <img :src="svgPath" />
    <slot></slot>
  </div>
</template>
