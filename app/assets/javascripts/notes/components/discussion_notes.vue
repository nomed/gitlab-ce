<script>
import { mapGetters } from 'vuex';
import { SYSTEM_NOTE } from '../constants';
import { __, n__ } from '~/locale';
import PlaceholderNote from '~/vue_shared/components/notes/placeholder_note.vue';
import PlaceholderSystemNote from '~/vue_shared/components/notes/placeholder_system_note.vue';
import SystemNote from '~/vue_shared/components/notes/system_note.vue';
import NoteableNote from './noteable_note.vue';
import ToggleRepliesWidget from './toggle_replies_widget.vue';
import NoteEditedText from './note_edited_text.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    ToggleRepliesWidget,
    NoteEditedText,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    isExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    diffLine: {
      type: Object,
      required: false,
      default: null,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    shouldGroupReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      repliesExpanded: true,
    };
  },
  computed: {
    ...mapGetters(['userCanReply']),
    hasReplies() {
      return Boolean(this.replies.length);
    },
    replies() {
      return this.discussion.notes.slice(1);
    },
    firstNote() {
      return this.discussion.notes.slice(0, 1)[0];
    },
    resolvedText() {
      return this.discussion.resolved_by_push ? __('Automatically resolved') : __('Resolved');
    },
    commit() {
      if (!this.discussion.for_commit) {
        return null;
      }

      return {
        id: this.discussion.commit_id,
        url: this.discussion.discussion_path,
      };
    },
    isReallyExpanded() {
      return this.discussion.diff_discussion ? this.repliesExpanded : this.isExpanded;
    },
  },
  methods: {
    componentName(note) {
      if (note.isPlaceholderNote) {
        if (note.placeholderType === SYSTEM_NOTE) {
          return PlaceholderSystemNote;
        }

        return PlaceholderNote;
      }

      if (note.system) {
        return SystemNote;
      }

      return NoteableNote;
    },
    componentData(note) {
      return note.isPlaceholderNote ? note.notes[0] : note;
    },
    toggleReplies() {
      if (this.discussion.diff_discussion) {
        this.repliesExpanded = !this.repliesExpanded;
      } else {
        this.$emit('toggleDiscussion');
      }
    },
  },
};
</script>

<template>
  <div class="discussion-notes">
    <ul class="notes">
      <template v-if="shouldGroupReplies">
        <component
          :is="componentName(firstNote)"
          :note="componentData(firstNote)"
          :line="line || diffLine"
          :commit="commit"
          :help-page-path="helpPagePath"
          :show-reply-button="userCanReply"
          @handle-delete-note="$emit('deleteNote')"
          @start-replying="$emit('startReplying')"
        >
          <note-edited-text
            v-if="discussion.resolved"
            slot="discussion-resolved-text"
            :edited-at="discussion.resolved_at"
            :edited-by="discussion.resolved_by"
            :action-text="resolvedText"
            class-name="discussion-headline-light js-discussion-headline discussion-resolved-text"
          />
          <slot slot="avatar-badge" name="avatar-badge"></slot>
        </component>
        <div
          :class="discussion.diff_discussion ? 'discussion-collapsible bordered-box clearfix' : ''"
        >
          <toggle-replies-widget
            v-if="hasReplies"
            :collapsed="!isReallyExpanded"
            :replies="replies"
            :class="discussion.diff_discussion ? 'discussion-toggle-replies' : ''"
            @toggle="toggleReplies"
          />
          <template v-if="isReallyExpanded">
            <component
              :is="componentName(note)"
              v-for="note in replies"
              :key="note.id"
              :note="componentData(note)"
              :help-page-path="helpPagePath"
              :line="line"
              @handle-delete-note="$emit('deleteNote')"
            />
          </template>
          <slot :show-replies="isReallyExpanded || !hasReplies" name="footer"></slot>
        </div>
      </template>
      <template v-else>
        <component
          :is="componentName(note)"
          v-for="(note, index) in discussion.notes"
          :key="note.id"
          :note="componentData(note)"
          :help-page-path="helpPagePath"
          :line="diffLine"
          @handle-delete-note="$emit('deleteNote')"
        >
          <slot v-if="index === 0" slot="avatar-badge" name="avatar-badge"></slot>
        </component>
        <slot :show-replies="isReallyExpanded || !hasReplies" name="footer"></slot>
      </template>
    </ul>
  </div>
</template>

<style>
.red {
  border: 1px solid red;
}
</style>
