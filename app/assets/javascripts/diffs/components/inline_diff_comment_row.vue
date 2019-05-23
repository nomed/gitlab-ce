<script>
import { mapActions } from 'vuex';
import diffDiscussions from './diff_discussions.vue';
import diffLineNoteForm from './diff_line_note_form.vue';
import ReplyPlaceholder from '../../notes/components/discussion_reply_placeholder.vue';

export default {
  components: {
    diffDiscussions,
    diffLineNoteForm,
    ReplyPlaceholder,
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
        <diff-line-note-form
          v-if="line.hasForm"
          :diff-file-hash="diffFileHash"
          :line="line"
          :note-target-line="line"
          :help-page-path="helpPagePath"
        />
        <div v-if="line.discussions.length && !line.hasForm" class="discussion-reply-holder">
          <reply-placeholder
            class="qa-discussion-reply"
            buttonText="Start a new discussion..."
            @onClick="showNewDiscussionForm"
          />
        </div>
      </div>
    </td>
  </tr>
</template>
