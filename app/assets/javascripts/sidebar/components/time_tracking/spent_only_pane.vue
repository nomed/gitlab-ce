<script>
export default {
  name: 'TimeTrackingSpentOnlyPane',
  props: {
    timeSpentHumanReadable: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="time-tracking-spend-only-pane">
    <span class="bold">{{ __('Spent:') }}</span> {{ timeSpentHumanReadable }}
  </div>
</template>
