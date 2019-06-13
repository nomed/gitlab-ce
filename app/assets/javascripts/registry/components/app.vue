<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import store from '../stores';
import CollapsibleContainer from './collapsible_container.vue';
import { s__ } from '../../locale';

const I18NKeys = {
  MainHeading: s__('ContainerRegistry|Container Registry'),
  MainMessage: s__(
    'ContainerRegistry|With the Docker Container Registry integrated into GitLab, every project can have its own space to store its Docker images. Learn more about the',
  ),
  CharacterErrorHeading: s__('ContainerRegistry|Docker connection error'),
  CharacterErrorMessage: s__(
    'ContainerRegistry|We are having trouble connecting to Docker, which could be due to an issue with your project name or path. For more information, please review the',
  ),
  CharacterErrorDocLink: s__('ContainerRegistry|Container Registry documentation'),
  NoImagesHeading: s__('ContainerRegistry|There are no container images stored for this project'),
  DefaultMessage: s__(
    'ContainerRegistry|With the Container Registry, every project can have its own space to store its Docker images. Learn more about the',
  ),
};

export default {
  name: 'RegistryListApp',
  components: {
    CollapsibleContainer,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    characterError: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    noContainersImage: {
      type: String,
      required: true,
    },
    containersErrorImage: {
      type: String,
      required: true,
    },
  },
  store,
  computed: {
    ...mapGetters(['isLoading', 'repos']),
    I18NKeys: () => I18NKeys,
  },
  created() {
    this.setMainEndpoint(this.endpoint);
  },
  mounted() {
    this.fetchRepos();
  },
  methods: {
    ...mapActions(['setMainEndpoint', 'fetchRepos']),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" :size="3"/>

    <div v-else-if="!isLoading && characterError" id="invalid-characters" class="container-message">
      <img :src="containersErrorImage">
      <h4>{{I18NKeys.CharacterErrorHeading}}</h4>
      <p>
        {{I18NKeys.CharacterErrorMessage}}
        <a :href="helpPagePath">{{I18NKeys.CharacterErrorDocLink}}</a>.
      </p>
    </div>

    <div v-else-if="!isLoading && !characterError && repos.length">
      <h4>{{I18NKeys.MainHeading}}</h4>
      <p>
        {{I18NKeys.MainMessage}}
        <a :href="helpPagePath">Container Registry</a>.
      </p>
      <collapsible-container v-for="item in repos" :key="item.id" :repo="item"/>
    </div>

    <div
      v-else-if="!isLoading && !characterError && !repos.length"
      id="no-container-images"
      class="container-message"
    >
      <img :src="noContainersImage">
      <h4>{{I18NKeys.NoImagesHeading}}</h4>
      <p>
        {{I18NKeys.DefaultMessage}}
        <a :href="helpPagePath">Container Registry</a>.
      </p>
    </div>
  </div>
</template>