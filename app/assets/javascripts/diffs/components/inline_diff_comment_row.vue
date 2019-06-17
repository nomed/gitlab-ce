<script>
import { mapActions, mapGetters } from 'vuex';
import diffDiscussions from './diff_discussions.vue';
import diffLineNoteForm from './diff_line_note_form.vue';
import ReplyPlaceholder from '../../notes/components/discussion_reply_placeholder.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    diffDiscussions,
    diffLineNoteForm,
    ReplyPlaceholder,
    UserAvatarLink,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    diffFileHash: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters(['getUserData']),
    className() {
      return this.line.discussions.length ? '' : 'js-temp-notes-holder';
    },
    shouldRender() {
      if (this.line.hasForm) return true;

      if (!this.line.discussions || !this.line.discussions.length) {
        return false;
      }
      return this.line.discussions.every(discussion => discussion.expanded);
    },
    currentUser() {
      return this.getUserData;
    },
  },
  methods: {
    ...mapActions('diffs', ['showCommentForm']),
    showNewDiscussionForm() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.diffFileHash });
    },
  },
};
</script>

<template>
  <tr v-if="shouldRender" :class="className" class="notes_holder">
    <td class="notes-content" colspan="3">
      <div class="content">
        <diff-discussions
          v-if="line.discussions.length"
          :line="line"
          :discussions="line.discussions"
          :help-page-path="helpPagePath"
        />
        <div class="discussion-reply-holder d-flex clearfix">
          <diff-line-note-form
            v-if="line.hasForm"
            :diff-file-hash="diffFileHash"
            :line="line"
            :note-target-line="line"
            :help-page-path="helpPagePath"
          />
          <template v-if="line.discussions.length && !line.hasForm">
            <user-avatar-link
              :link-href="currentUser.path"
              :img-src="currentUser.avatar_url"
              :img-alt="currentUser.name"
              :img-size="40"
              class="d-none d-sm-block"
            />
            <reply-placeholder
              class="qa-discussion-reply"
              button-text="Start a new discussion..."
              @onClick="showNewDiscussionForm"
            />
          </template>
        </div>
      </div>
    </td>
  </tr>
</template>
