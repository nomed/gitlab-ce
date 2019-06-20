<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters(['getNotesDataByProp']),
    registerLink() {
      return this.getNotesDataByProp('registerPath');
    },
    signInLink() {
      return this.getNotesDataByProp('newSessionPath');
    },
  },
};
</script>

<template>
  <div class="disabled-comment text-center">
    Please <a :href="registerLink">{{ __("register") }}</a> or <a :href="signInLink">{{ __("sign in") }}</a> to reply
  </div>
</template>
